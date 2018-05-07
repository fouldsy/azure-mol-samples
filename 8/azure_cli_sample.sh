#!/bin/bash

# This script sample is part of "Learn Azure in a Month of Lunches" (Manning
# Publications) by Iain Foulds.
#
# This sample script covers the exercises from chapter 8 of the book. For more
# information and context to these commands, read a sample of the book and
# purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
#
# This script sample is released under the MIT license. For more information,
# see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

# Create a resource group
az group create --name azuremolchapter8 --location westeurope

# Create a public IP address
# This public IP address is assigned to an Azure load balancer in the next comman
# To use with Availability Zones, a standard SKU resource is created
az network public-ip create \
    --resource-group azuremolchapter8 \
    --name publicip \
    --sku standard

# Create an Azure load balancer
# This load balancer distributes traffic from the frontend IP pool to backend VMs
# The public IP address created in the previous command is attached to the frontend IP pool
# For use with Availability Zones, a standard SKU resource is created
az network lb create \
    --resource-group azuremolchapter8 \
    --name loadbalancer \
    --public-ip-address publicip \
    --frontend-ip-name frontendpool \
    --backend-pool-name backendpool \
    --sku standard

# Create a load balancer health probe
# The health probe checks for an HTTP 200 OK response from health.html on port 80 of each VM
# The probe checks every 10 seconds, and removes a VM from load balancer distribution if no response
# is received after 3 consecutive failures
# This health probe ensures that only VMs that can correctly serve traffic receive customer requests
# from the load balancer
az network lb probe create \
    --resource-group azuremolchapter8 \
    --lb-name loadbalancer \
    --name healthprobe \
    --protocol http \
    --port 80 \
    --path health.html \
    --interval 10 \
    --threshold 3

# Create a load balancer rules
# Rules define how to distribute traffic from the frontend pool to the backend VMs
# For common HTTP traffic, route TCP port 80 traffic
# The health probe is used to ensure only active VMs receive traffic distribution
az network lb rule create \
    --resource-group azuremolchapter8 \
    --lb-name loadbalancer \
    --name httprule \
    --protocol tcp \
    --frontend-port 80 \
    --backend-port 80 \
    --frontend-ip-name frontendpool \
    --backend-pool-name backendpool \
    --probe-name healthprobe

# Create a Network Address Translation (NAT) rule
# The NAT rule allows you to connect directly to VMs on a specific port
# Here, TCP port 50001 is opened that maps to TCP port 22 on the VMs
az network lb inbound-nat-rule create \
    --resource-group azuremolchapter8 \
    --lb-name loadbalancer \
    --name natrulessh \
    --protocol tcp \
    --frontend-port 50001 \
    --backend-port 22 \
    --frontend-ip-name frontendpool

# Create a virtual network and subnet
# The VMs connect to these network resources
az network vnet create \
    --resource-group azuremolchapter8 \
    --name vnetmol \
    --address-prefixes 10.0.0.0/16 \
    --subnet-name subnetmol \
    --subnet-prefix 10.0.1.0/24

# Create a Network Security Group
# This security group filters inbound and outbound traffic, allowing or denying traffic based on
# rules that you define
az network nsg create \
    --resource-group azuremolchapter8 \
    --name webnsg

# Create a Network Security Group rule
# To allow web traffic to reach your VMs through the load balancer, allow TCP port 80
# Without this rule, the load balancer would distribute traffic to the backend VMs, however the traffic
# from customers is blocked from reaching the VMs
az network nsg rule create \
    --resource-group azuremolchapter8 \
    --nsg-name webnsg \
    --name allowhttp \
    --priority 100 \
    --protocol tcp \
    --destination-port-range 80 \
    --access allow

# Create a Network Security Group rule
# To allow SSH traffic to reach your VMs through the load balancer, allow TCP port 22
az network nsg rule create \
    --resource-group azuremolchapter8 \
    --nsg-name webnsg \
    --name allowssh \
    --priority 101 \
    --protocol tcp \
    --destination-port-range 22 \
    --access allow

# Update the virtual network subnet to attach the Network Security Group
# Network Security Group resources can be attached to a subnet or virtual NIC
az network vnet subnet update \
    --resource-group azuremolchapter8 \
    --vnet-name vnetmol \
    --name subnetmol \
    --network-security-group webnsg

# Create a virtual network interface card
# We create the NIC here to attach it to the network subnet, load balancer, and NAT rules
# This step makes sure that the VM is secured as soon as it is created
az network nic create \
    --resource-group azuremolchapter8 \
    --name webnic1 \
    --vnet-name vnetmol \
    --subnet subnetmol \
    --lb-name loadbalancer \
    --lb-address-pools backendpool \
    --lb-inbound-nat-rules natrulessh

# Create a virtual NIC for use with the second VM
az network nic create \
    --resource-group azuremolchapter8 \
    --name webnic2 \
    --vnet-name vnetmol \
    --subnet subnetmol \
    --lb-name loadbalancer \
    --lb-address-pools backendpool

# Create the first VM
# Attach the first virtual NIC created in a previous step
# For high availability, create the VM in zone 1
az vm create \
    --resource-group azuremolchapter8 \
    --name webvm1 \
    --image ubuntults \
    --size Standard_B1ms \
    --admin-username azuremol \
    --generate-ssh-keys \
    --zone 1 \
    --nics webnic1

# Apply the Custom Script Extension
# The Custom Script Extension runs on the first VM to install NGINX, clone the samples repo, then
# copy the example web files to the required location
az vm extension set \
    --publisher Microsoft.Azure.Extensions \
    --version 2.0 \
    --name CustomScript \
    --resource-group azuremolchapter8 \
    --vm-name webvm1 \
    --settings '{"fileUris":["https://raw.githubusercontent.com/fouldsy/azure-mol-samples/master/8/install_webvm1.sh"],"commandToExecute":"sh install_webvm1.sh"}'

# Create the second VM
# Attach the second virtual NIC created in a previous step
# For high availability, create the VM in zone 2
az vm create \
    --resource-group azuremolchapter8 \
    --name webvm2 \
    --image ubuntults \
    --size Standard_B1ms \
    --admin-username azuremol \
    --generate-ssh-keys \
    --zone 2 \
    --nics webnic2

# Apply the Custom Script Extension
# The Custom Script Extension runs on the second VM to install NGINX, clone the samples repo, then
# copy the example web files to the required location
az vm extension set \
    --publisher Microsoft.Azure.Extensions \
    --version 2.0 \
    --name CustomScript \
    --resource-group azuremolchapter8 \
    --vm-name webvm2 \
    --settings '{"fileUris":["https://raw.githubusercontent.com/fouldsy/azure-mol-samples/master/8/install_webvm2.sh"],"commandToExecute":"sh install_webvm2.sh"}'

# Show the public IP address that is attached to the load balancer
# To see your application in action, open this IP address in a web browser
publicIp=$(az network public-ip show \
    --resource-group azuremolchapter8 \
    --name publicip \
    --query ipAddress \
    --output tsv)

# Now you can access the load balancer and web servers in your web browser
echo "To see your load balancer in action, enter the public IP address in to your web browser: http://$publicIp"
