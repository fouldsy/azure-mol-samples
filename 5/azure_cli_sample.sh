# Create a resource group
az group create --name azuremolchapter5 --location eastus

# Create a virtual network and subnet
# The virtual network and subnet both create regular IP ranges assigned
# to them, just like an on-premises network
az network vnet create \
    --resource-group azuremolchapter5 \
    --name vnetmol \
    --address-prefix 10.0.0.0/16 \
    --subnet-name websubnet \
    --subnet-prefix 10.0.1.0/24

# Create a public IP address
# This public IP address assigned gets assigned to a web server VM in a
# following step. We also assigned the DNS prefix of `webmol`
az network public-ip create \
    --resource-group azuremolchapter5 \
    --name webpublicip \
    --dns-name webmol

# Create a virtual network adapter
# All VMs need a virtual network interace card (vNIC) that connects them to a
# virtual network subnet. We assign the public IP address created in the previos
# step, along with the a static internal IP address of 10.0.1.4
az network nic create \
    --resource-group azuremolchapter5 \
    --name webvnic \
    --vnet-name vnetmol \
    --subnet websubnet \
    --public-ip-address webpublicip \
    --private-ip-address 10.0.1.4

# Create network security group
# A network security group secures and filters both inbound + outbound virtual
# network traffic
az network nsg create \
    --resource-group azuremolchapter5 \
    --name webnsg

# Associate the network security group with your virtual network
# Network security groups can be assigned to a virtual network subnet, as we do
# here, or to an individual vNIC
az network vnet subnet update \
    --resource-group azuremolchapter5 \
    --vnet-name vnetmol \
    --name websubnet \
    --network-security-group webnsg

# Add a network security group rule to allow port 80
# Rules can be applied to inbound or outbound traffic, to a specific protocol or
# port, and for certain IP address ranges or port ranges
az network nsg rule create \
    --resource-group azuremolchapter5 \
    --nsg-name webnsg \
    --name allowhttp \
    --access allow \
    --protocol tcp \
    --direction inbound \
    --priority 100 \
    --source-address-prefix "*" \
    --source-port-range "*" \
    --destination-address-prefix "*" \
    --destination-port-range 80

# Create an additional network security group for remote access
az network nsg create \
    --resource-group vnetmol \
    --name remotensg

# Create an additional network security group rule to allow SSH connections
# Here, we don't specify the address prefixes,direction, or destinations, as the
# Azure CLI can use smart defaults to populate these for us
az network nsg rule create \
    --resource-group vnetmol \
    --nsg-name remotensg \
    --name allowssh \
    --protocol tcp \
    --priority 100 \
    --destination-port-range 22 \
    --access allow

# Create an additional virtual network subnet and associate our remote network
# security group. This is a little different to the previous steps where we
# associated a network security group with a virtual network subnet.
az network vnet subnet create \
    --resource-group vnetmol \
    --vnet-name vnetmol \
    --name remotesubnet \
    --address-prefix 10.0.2.0/24 \
    --network-security-group remotensg

# Create a VM that will act as a web server
# Attach the virtual NIC created in the previous steps
az vm create \
    --resource-group vnetmol \
    --name webvm \
    --nics webvnic \
    --image UbuntuLTS \
    --admin-username adminuser \
    --generate-ssh-keys

# Create a VM that will act as our remote connection VM
# Connect the VM to the virtual network subnet for remote connectivity
az vm create \
    --resource-group vnetmol \
    --name remotevm \
    --vnet-name vnetmol \
    --subnet remotesubnet \
    --nsg remotenmsg \
    --public-ip-address remotepublicip \
    --image ubuntults \
    --admin-username adminuser \
    --generate-ssh-keys

# Enable the SSH agent and add our SSH keys
eval $(ssh-agent)
ssh-add

# Obtain the public IP address of the web server VM
webvm_ip=$(az vm show \
    --resource-group azuremolchapter5 \
    --name webvm \
    --show-details \
    --query publicIps \
    --output tsv)

# SSH to the remote VM, passing through our SSH keys
ssh -A adminuser@$webvm_ip

# Now, SSH to the internal IP address of the web server. This server is otherwise
# secure and cannot be connected to via SSH directly
ssh 10.0.1.4