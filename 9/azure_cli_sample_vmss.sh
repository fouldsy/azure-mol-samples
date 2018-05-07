#!/bin/bash

# This script sample is part of "Learn Azure in a Month of Lunches" (Manning
# Publications) by Iain Foulds.
#
# This sample script covers the exercises from chapter 9 of the book. For more
# information and context to these commands, read a sample of the book and
# purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
#
# This script sample is released under the MIT license. For more information,
# see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

# Create a resource group
az group create --name azuremolchapter9 --location westeurope

# Create a virtual machine scale set
# Three VM instances are created, along with a load balancer
# For high availability, a standard SKU LB is created, and the VM instanes are distributed
# across zone 1
az vmss create \
    --resource-group azuremolchapter9 \
    --name scalesetmol \
    --image UbuntuLTS \
    --admin-username azuremol \
    --generate-ssh-keys \
    --instance-count 2 \
    --vm-sku Standard_B1ms \
    --upgrade-policy-mode automatic \
    --lb-sku standard \
    --zones 1 2 3

# Manually scale the number of VM instances up to 4 instances
az vmss scale \
    --resource-group azuremolchapter9 \
    --name scalesetmol \
    --new-capacity 4

# Add autoscale profile and rules to scale set
# First, create an autoscale profile that is applied to the scale set
# Set a default, minimum, and maximum number of instances for scaling
az monitor autoscale create \
    --resource-group azuremolchapter9 \
    --name autoscalevmss \
    --resource scalesetmol \
    --resource-type Microsoft.Compute/virtualMachineScaleSets
    --min-count 2 \
    --max-count 10 \
    --count 2

# Create an autoscale rule to scale out the number of VM instances
# When the average CPU load is greater than 70% over 10 minutes, increase by 1 instance
az monitor autoscale rule create \
    --resource-group azuremolchapter9 \
    --autoscale-name autoscalevmss \
    --scale out 1 \
    --condition "Percentage CPU > 70 avg 10m"

# Create an autoscale rule to scale in the number of VM instances
# When the average CPU load is less than 30% over 5 minutes, decrease by 1 instance
az monitor autoscale rule create \
    --resource-group azuremolchapter9 \
    --autoscale-name autoscalevmss \
    --scale in 1 \
    --condition "Percentage CPU < 30 avg 5m"
 
# Apply the Custom Script Extension
# This extension installs the NGINX web server on each VM instance in the scale set
az vmss extension set \
    --publisher Microsoft.Azure.Extensions \
    --version 2.0 \
    --name CustomScript \
    --resource-group azuremolchapter9 \
    --vmss-name scalesetmol \
    --settings '{"commandToExecute":"apt-get -y update && apt-get -y install nginx"}'

# Show the public IP address that is attached to the load balancer
# To see your application in action, open this IP address in a web browser
publicIp=$(az network public-ip show \
    --resource-group azuremolchapter9 \
    --name scalesetmolLBPublicIP \
    --query ipAddress \
    --output tsv)

# Now you can access the scale set's load balancer in your web browser
echo "To see your scale set in action, enter the public IP address of the load balancer in to your web browser: http://$publicIp"
