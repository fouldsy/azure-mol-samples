#!/bin/bash

# This script sample is part of "Learn Azure in a Month of Lunches" (Manning
# Publications) by Iain Foulds.
#
# This sample script covers the exercises from chapter 11 of the book. For more
# information and context to these commands, read a sample of the book and
# purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
#
# This script sample is released under the MIT license. For more information,
# see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

# Define variables for unique resource names
# As we create DNS entries for Traffic Manager profiles and Web Apps, these
# DNS names must be unique. By adding some randomization to the resource names, the
# commands can run without user intervention or errors. Feel free to provide your own
# varation of unique names for use throughout the script
trafficManagerDNSName=azuremol$RANDOM
trafficManagerDNSEastUS=azuremoleastus$RANDOM
trafficManagerDNSWestEurope=azuremolwesteurope$RANDOM
webAppNameEastUS=azuremoleastus$RANDOM
webAppNameWestEurope=azuremolwesteurope$RANDOM

# Create a resource group
az group create --name azuremolchapter11 --location eastus

# Create a Traffic Manager profile
# This parent profile is used as the entry point for your application traffic
# In later steps, child profiles for individual Azure regions are created and attached
az network traffic-manager profile create \
    --resource-group azuremolchapter11 \
    --name azuremol \
    --routing-method geographic \
    --unique-dns-name $trafficManagerDNSName

# Create a Traffic Manager profile for East US
az network traffic-manager profile create \
    --resource-group azuremolchapter11 \
    --name eastus \
    --routing-method priority \
    --unique-dns-name $trafficManagerDNSEastUS

# Create a Traffic Manager profile for West Europe
az network traffic-manager profile create \
    --resource-group azuremolchapter11 \
    --name westeurope \
    --routing-method priority \
    --unique-dns-name $trafficManagerDNSWestEurope

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
    --name $webAppNameEastUS \
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
    --name $webAppNameWestEurope \
    --plan appservicewesteurope \
    --deployment-local-git 

# Add endpoint for East US Traffic Manager profile
# This endpoint is for the East US Web App, and sets with a high priority of 1
az network traffic-manager endpoint create \
    --resource-group azuremolchapter11 \
    --name eastus \
    --profile-name eastus \
    --type azureEndpoints \
    --target-resource-id $(az webapp show \
        --resource-group azuremolchapter11 \
        --name $webAppNameEastUS \
        --query id \
        --output tsv) \
    --priority 1

# Add endpoint for East US Traffic Manager profile
# This endpoint is for the West Europe Web App, and sets with a low priority of 100
az network traffic-manager endpoint create \
    --resource-group azuremolchapter11 \
    --name westeurope \
    --profile-name eastus \
    --type azureEndpoints \
    --target-resource-id $(az webapp show \
        --resource-group azuremolchapter11 \
        --name $webAppNameWestEurope \
        --query id \
        --output tsv) \
    --priority 100

# Add endpoint for West Europe Traffic Manager profile
# This endpoint is for the West Europe Web App, and sets with a high priority of 1
az network traffic-manager endpoint create \
    --resource-group azuremolchapter11 \
    --name westeurope \
    --profile-name westeurope \
    --type azureEndpoints \
    --target-resource-id $(az webapp show \
        --resource-group azuremolchapter11 \
        --name $webAppNameWestEurope \
        --query id \
        --output tsv) \
    --priority 1

# Add endpoint for West Europe Traffic Manager profile
# This endpoint is for the East US Web App, and sets with a low priority of 100
az network traffic-manager endpoint create \
    --resource-group azuremolchapter11 \
    --name eastus \
    --profile-name westeurope \
    --type azureEndpoints \
    --target-resource-id $(az webapp show \
        --resource-group azuremolchapter11 \
        --name $webAppNameEastUS \
        --query id \
        --output tsv) \
    --priority 100

# Add nested profile to parent Traffic Manager geographic routing profile
# The East US Traffic Manager profile is attached to the parent Traffic Manager profile
az network traffic-manager endpoint create \
    --resource-group azuremolchapter11 \
    --name eastus \
    --profile-name azuremol \
    --type nestedEndpoints \
    --target-resource-id $(az network traffic-manager profile show \
        --resource-group azuremolchapter11 \
        --name eastus \
        --query id \
        --output tsv) \
    --geo-mapping GEO-NA \
    --min-child-endpoints 1

# Add nested profile to parent Traffic Manager geographic routing profile
# The West Europe Traffic Manager profile is attached to the parent Traffic Manager profile
az network traffic-manager endpoint create \
    --resource-group azuremolchapter11 \
    --name westeurope \
    --profile-name azuremol \
    --type nestedEndpoints \
    --target-resource-id $(az network traffic-manager profile show \
        --resource-group azuremolchapter11 \
        --name westeurope \
        --query id \
        --output tsv) \
    --geo-mapping GEO-EU \
    --min-child-endpoints 1

# Add custom hostname to Web App
# As we want to distribute traffic from each region through the central Traffic Manager profile, the
# Web App must identify itself on a custom domain
# This hostname is for the East US Web App
az webapp config hostname add \
    --resource-group azuremolchapter11 \
    --webapp-name $webAppNameEastUS \
    --hostname $trafficManagerDNSName.trafficmanager.net

# Add custom hostname to Web App
# As we want to distribute traffic from each region through the central Traffic Manager profile, the
# Web App must identify itself on a custom domain
# This hostname is for the East US Web App
az webapp config hostname add \
    --resource-group azuremolchapter11 \
    --webapp-name $webAppNameWestEurope \
    --hostname $trafficManagerDNSName.trafficmanager.net

# Create a Git user accout and set credentials
# Deployment users are used to authenticate with the App Service when you
# upload your web application to Azure
az webapp deployment user set \
    --user-name azuremol \
    --password M0lPassword!

# Clone the Azure MOL sample repo, if you haven't already
cd ~ && git clone https://github.com/fouldsy/azure-mol-samples.git

# Initialize and push the Web Application with Git for the East US Web App
cd ~/azure-mol-samples/11/eastus
git remote remove eastus
git init && git add . && git commit -m “Pizza”
git remote add eastus $(az webapp deployment source config-local-git \
    --resource-group azuremolchapter11 \
    --name $webAppNameEastUS -o tsv)
git push eastus master

# Initialize and push the Web Application with Git for the West Europe Web App
cd ~/azure-mol-samples/11/westeurope
git remote remove westeurope
git init && git add . && git commit -m “Pizza”
git remote add westeurope $(az webapp deployment source config-local-git \
    --resource-group azuremolchapter11 \
    --name $webAppNameWestEurope -o tsv)
git push westeurope master

# Get the hostname of the parent Traffic Manager profile
# This hostname is set to the variable hostName and output to the screen in the next command
hostName=$(az network traffic-manager profile show \
    --resource-group azuremolchapter11 \
    --name azuremol \
    --query dnsConfig.fqdn \
    --output tsv)

# Now you can access the Traffic Manager profile and Web Apps
echo "To see your Traffic Manager and Web Apps in action, enter the following address in to your web browser:" $hostName
