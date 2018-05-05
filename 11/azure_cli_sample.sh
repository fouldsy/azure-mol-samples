# Create a resource group
az group create --name azuremolchapter11 --location eastus

# Create a Traffic Manager profile
# This parent profile is used as the entry point for your application traffic
# In later steps, child profiles for individual Azure regions are created and attached
az network traffic-manager profile create \
    --resource-group azuremolchapter11 \
    --name azuremol \
    --routing-method geographic \
    --unique-dns-name azuremol

# Create a Traffic Manager profile for East US
az network traffic-manager profile create \
    --resource-group azuremolchapter11 \
    --name eastus \
    --routing-method priority \
    --unique-dns-name azuremoleastus

# Create a Traffic Manager profile for West Europe
az network traffic-manager profile create \
    --resource-group azuremolchapter11 \
    --name westeurope \
    --routing-method priority \
    --unique-dns-name azuremolwesteurope

# Create an App Service plan
# Two Web Apps are created, one for East US, and one for West Europe
# This App Service plan is for the East US Web App
az appservice plan create \
    --resource-group azuremolchapter11 \
    --name appserviceeastus \
    --location eastus \
    --sku S1

# Create a Web App
# This Web App is for traffic in East US
# Git is used as the deployment method
az webapp create \
    --resource-group azuremolchapter11 \
	--name azuremoleastus \
	--plan appserviceeastus \
	--deployment-local-git

# Create an App Service plan
# Two Web Apps are created, one for East US, and one for West Europe
# This App Service plan is for the West Europe Web App
az appservice plan create \
    --resource-group azuremolchapter11 \
    --name appservicewesteurope \
    --location westeurope \
    --sku S1

# Create a Web App
# This Web App is for traffic in East US
# Git is used as the deployment method
az webapp create \
    --resource-group azuremolchapter11 \
    --name azuremolwesteurope \
	--plan appservicewesteurope \
	--deployment-local-git 

# Add endpoint for East US Traffic Manager profile
# This endpoint is for the East US Web App, and sets with a high priority of 1
az network traffic-manager endpoint create \
    --resource-group azuremolchapter11 \
    --name eastus \
    --profile-name eastus \
    --type azureEndpoints \
    --target $(az webapp show \
        --resource-group azuremolchapter11 \
        --name eastus
        --query
        --output tsv)
    --priority 1

# Add endpoint for East US Traffic Manager profile
# This endpoint is for the West Europe Web App, and sets with a low priority of 100
az network traffic-manager endpoint create \
    --resource-group azuremolchapter11 \
    --name eastus \
    --profile-name eastus \
    --type azureEndpoints \
    --target $(az webapp show \
        --resource-group azuremolchapter11 \
        --name westeurope
        --query
        --output tsv)
    --priority 100

# Add endpoint for West Europe Traffic Manager profile
# This endpoint is for the West Europe Web App, and sets with a high priority of 1
az network traffic-manager endpoint create \
    --resource-group azuremolchapter11 \
    --name westeurope \
    --profile-name westeurope \
    --type azureEndpoints \
    --target $(az webapp show \
        --resource-group azuremolchapter11 \
        --name westeurope
        --query
        --output tsv)
    --priority 1

# Add endpoint for West Europe Traffic Manager profile
# This endpoint is for the East US Web App, and sets with a low priority of 100
az network traffic-manager endpoint create \
    --resource-group azuremolchapter11 \
    --name westeurope \
    --profile-name eastus \
    --type azureEndpoints \
    --target $(az webapp show \
        --resource-group azuremolchapter11 \
        --name eastus
        --query
        --output tsv)
    --priority 100

# Add nested profile to parent Traffic Manager geographic routing profile
# The East US Traffic Manager profile is attached to the parent Traffic Manager profile
az network traffic-manager endpoint create \
    --resource-group azuremolchapter11 \
    --namee eastus \
    --profile-name azuremol \
    --type nestedEndpoints \
    --target $(az network traffic-manager profile show \
        --resource-group azuremolchapter11 \
        --name eastus
        --query
        --output tsv)
    --geo-mapping

# Add nested profile to parent Traffic Manager geographic routing profile
# The West Europe Traffic Manager profile is attached to the parent Traffic Manager profile
az network traffic-manager endpoint create \
    --resource-group azuremolchapter11 \
    --name westeurope \
    --profile-name azuremol \
    --type nestedEndpoints \
    --target $(az network traffic-manager profile show \
        --resource-group azuremolchapter11 \
        --name westeurope
        --query
        --output tsv)
    --geo-mapping 

# Add custom hostname to Web App
# As we want to distribute traffic from each region through the central Traffic Manager profile, the
# Web App must identify itself on a custom domain
# This hostname is for the East US Web App
az webapp config hostname add \
    --resource-group azuremolchapter11 \
    --webapp-name azuremoleastus \
    --hostname azuremol.trafficmanager.net

# Add custom hostname to Web App
# As we want to distribute traffic from each region through the central Traffic Manager profile, the
# Web App must identify itself on a custom domain
# This hostname is for the East US Web App
az webapp config hostname add \
    --resource-group azuremolchapter11 \
    --webapp-name azuremolwesteurope \
    --hostname azuremol.trafficmanager.net

# Initialize and push the Web Application with Git for the East US Web App
cd azure-mol-samples/11/eastus
git init && git add . && git commit -m “Pizza”
git remote add eastus <your-git-clone-url>
git push eastus master

# Initialize and push the Web Application with Git for the West Europe Web App
cd azure-mol-samples/11/westeurope
git init && git add . && git commit -m “Pizza”
git remote add westeurope <your-git-clone-url>
git push westeurope master