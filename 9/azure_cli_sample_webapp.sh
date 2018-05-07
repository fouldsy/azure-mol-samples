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

# Define variables for unique Web App name.
# As we create DNS for the Web App, the DNS name must be unique. By adding some
# randomization to the resource name, the commands can run without user 
# intervention or errors. Feel free to provide your own varation of unique 
# name for use throughout the script
webAppName=azuremol$RANDOM

# Create a resource group
az group create --name azuremolchapter9 --location westeurope

# Create an App Service plan
# A Standard SKU plan is created for general use
az appservice plan create \
    --name appservicemol \
    --resource-group azuremolchapter9 \
    --sku s1

# Create a Web App
# The Web App uses the App Service plan created in the previous step
# To deploy your application, the Web App is configured to use Git
az webapp create \
    --name $webAppName \
    --resource-group azuremolchapter9 \
    --plan appservicemol \
    --deployment-local-git

# Add autoscale profile and rules to Web App
# Although the Web App instances are scaled, the scaling is applied to the App Service itself
# First, create an autoscale profile that is applied to the Web App
# Set a default, minimum, and maximum number of instances for scaling
az monitor autoscale create \
    --resource-group azuremolchapter9 \
    --name autoscalewebapp \
    --resource appservicemol \
    --resource-type Microsoft.Web/serverfarms \
    --min-count 2 \
    --max-count 5 \
    --count 2

# Create an autoscale rule to scale out the number of Web Apps
# When the average CPU load is greater than 70% over 10 minutes, increase by 1 instance
az monitor autoscale rule create \
    --resource-group azuremolchapter9 \
    --autoscale-name autoscalewebapp \
    --scale out 1 \
    --condition "Percentage CPU > 70 avg 10m"

# Create an autoscale rule to scale in the number of Web Apps
# When the average CPU load is less than 30% over 5 minutes, decrease by 1 instance
az monitor autoscale rule create \
    --resource-group azuremolchapter9 \
    --autoscale-name autoscalewebapp \
    --scale in 1 \
    --condition "Percentage CPU < 30 avg 5m"

# Create a Git user accout and set credentials
# Deployment users are used to authenticate with the App Service when you
# upload your web application to Azure
az webapp deployment user set \
    --user-name azuremol \
    --password M0lPassword!

# Clone the Azure MOL sample repo, if you haven't already
cd ~ && git clone https://github.com/fouldsy/azure-mol-samples.git
cd azure-mol-samples/9

# Initialize a basic Git repo for the web application
git init && git add . && git commit -m “Pizza”

# Add your Web App as a remote destination in Git
git remote add webappmolscale $(az webapp deployment source config-local-git \
    --resource-group azuremolchapter9 \
    --name $webAppName -o tsv)

# Push the sample web application to your Web App
git push webappmolscale master

# Get the hostname of the Web App
# This hostname is set to the variable hostName and output to the screen in the next command
hostName=$(az webapp show --resource-group azuremolchapter9 --name $webAppName --query defaultHostName --output tsv)

# Now you can access the Web App in your web browser
echo "To see your Web App in action, enter the following address in to your web browser:" $hostName