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
	--instance-count 3 \
	--upgrade-policy-mode automatic \
	--lb-sku standard \
	--zones 1

# Manually scale the number of VM instances up to 5 instances
az vmss scale \
    --resource-group azuremolchapter9 \
    --name scalesetmol \
    --new-capacity 5

# Add autoscale profile and rules to scale set

# Create a load balancer rule
# This rule allows HTTP traffic on TCP port 80 for basic web server access
# In the next step, you install the NGINX web server on each VM instance in the scale set
az network lb rule create \
    --resource-group azuremolchapter9 \
    --name webloadbalancer \
    --lb-name scalesetmolLB \
    --backend-pool-name scalesetmolLBBEPool \
    --backend-port 80 \
    --frontend-ip-name loadBalancerFrontEnd \
    --frontend-port 80 \
    --protocol tcp
 
 # Apply the Custom Script Extension
 # This extension installs the NGINX web server on each VM instance in the scale set
 az vmss extension set