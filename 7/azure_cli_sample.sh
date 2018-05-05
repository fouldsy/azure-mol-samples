# Create a resource group
az group create --name azuremolchapter7az --location westeurope

# Create a public IP address
# This public IP address is assigned to an Azure load balancer in the next command
# To use the public IP address with Availability Zones, a Standard SKU resource is created
# The traffic is routed to a single zone, but the metadata for the address exists across all Zones
# If one zone is unavailable, the Azure platform routes the traffic to an available zone
az network public-ip create \
    --resource-group azuremolchapter7az \
    --name azpublicip \
    --sku standard

# Create an Azure load balancer
# As with the public IP address, a standard SKU resource is created
# The core traffic is distributed from one zone, but can failover to another zone as needed
az network lb create \
    --resource-group azuremolchapter7az \
    --name azloadbalancer \
    --public-ip-address azpublicip \
    --frontend-ip-name frontendpool \
    --backend-pool-name backendpool \
    --sku standard

# Create the first VM
# You manually specify a zone for the VM. There is no built-in automated distribution of VMs
# across Availability Zones
# This command creates a VM in zone 1
az vm create \
	--resource-group azuremolchapter7az \
	--name zonedvm1 \
	--image ubuntults \
	--size Standard_B1ms \
	--admin-username azuremol \
	--generate-ssh-keys \
	--zone 1

# Create a second VM
# This VM is manually defined to be created in zone 3
az vm create \
	--resource-group azuremolchapter7az \
	--name zonedvm3 \
	--image ubuntults \
	--size Standard_B1ms \
	--admin-username azuremol \
	--generate-ssh-keys \
	--zone 3