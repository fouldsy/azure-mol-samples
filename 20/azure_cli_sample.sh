#!/bin/bash

# This script sample is part of "Learn Azure in a Month of Lunches" (Manning
# Publications) by Iain Foulds.
#
# This sample script covers the exercises from chapter 20 of the book. For more
# information and context to these commands, read a sample of the book and
# purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
#
# This script sample is released under the MIT license. For more information,
# see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

# Create a resource group
az group create --name azuremolchapter20 --location eastus

# Create an IoT Hub
# A Hub provides you with a way to connect, provision, and secure IoT devices
# and allow other services and applications to use the IoT devices. The free
# tier is used, which allows up to 8,000 messages per day.
az iot hub create \
    --resource-group azuremolchapter20 \
    --name azuremol \
    --sku f1

# Add the Azure IoT CLI extension
# This CLI extension provides some additional functionality to the core Azure
# CLI 2.0, and can be updated out-of-band from the core tooling itself.
az extension add --name azure-cli-iot-ext

# Create an IoT identity
# An identity is used by an IoT device to connect to the Azure IoT Hub. Each
# device has a unique identity. This identity can be used for a simulated, or
# real Raspberry Pi device.
az iot hub device-identity create \
    --hub-name azuremol \
    --device-id raspberrypi

# Show the IoT device connection string
# This connection string can be provided to your IoT device to allow it to
# connect to the Azure IoT Hub.
az iot hub device-identity show-connection-string \
    --hub-name azuremol \
    --device-id raspberrypi \
    --output tsv

# Show the status of the IoT device and message quota
# As your device connects and transmits messages, the change in quota can be
# viewed.
az iot hub show-quota-metrics --name azuremol

# Create an App Service plan
# An App Service plan defines the location and available features
# These features include deployment slots, traffic routing options, and
# security options.
az appservice plan create \
    --resource-group azuremolchapter20 \
    --name azuremol \
    --sku f1

# Define variable for unique Web App name.
# As we create DNS for the Web App, the DNS name must be unique. By adding some
# randomization to the resource name, the commands can run without user 
# intervention or errors. Feel free to provide your own varation of unique 
# name for use throughout the script.
webAppName=azuremol$RANDOM

# Create a Web App in the App Service plan enabled for local Git deployments
# The Web App is what actually runs your web site, lets you create deployment
# slots, stream logs, etc.
az webapp create \
    --resource-group azuremolchapter20 \
    --plan azuremol \
    --name $webAppName \
    --deployment-local-git

# Create an Azure IoT Hub consumer group
# A consumer group allows you to define messages that are streamed to available
# connected services and applications. By default, messages received from IoT
# device are placed on a shared events endpoint.
az iot hub consumer-group create \
    --hub-name azuremol \
    --name molwebapp

# Set a Web App application setting for the consumer group
# Application settings let you define variables that are available to your Web
# Apps. This allows you to dynamically adjust names, connection strings, etc.
# without needing to update your code.
az webapp config appsettings set \
    --resource-group azuremolchapter20 \
    --name $webAppName \
    --settings consumergroup=molwebapp

# Obtain the IoT connection string for use with Web App connection
iotconnectionstring=$(az iot hub show-connection-string \
                        --hub-name azuremol \
                        --output tsv)

# Create another Web App application setting for the connection string
# This setting allows your Web App to connect to Azure IoT Hub without
# needing to update your code.
az webapp config appsettings set \
    --resource-group azuremolchapter20 \
    --name $webAppName \
    --settings iot=$iotconnectionstring

# Finally, enable websockets on the Web App
# Websockets allows your app to dynamically update the web browser when a user
# is connected to displayed the latest information from your IoT device
az webapp config set \
    --resource-group azuremolchapter20 \
    --name $webAppName \
    --web-sockets-enabled

# Create a Git user accout and set credentials
# Deployment users are used to authenticate with the App Service when you
# upload your web application to Azure.
az webapp deployment user set \
    --user-name azuremol \
    --password M0lPassword!

# Clone the Azure MOL sample repo, if you haven't already
cd ~ && git clone https://github.com/fouldsy/azure-mol-samples.git
cd azure-mol-samples/20

# Initialize the directory for use with Git, add the sample files, and commit
git init && git add . && git commit -m “Pizza”

# Add your Web App as a remote destination in Git
git remote add molwebappiot \
    $(az webapp deployment source config-local-git \
        --resource-group azuremolchapter20 \
        --name $webAppName -o tsv)

# Push, or upload, the sample app to your Web App
git push molwebappiot master

# Get the hostname of the Web App
# This hostname is set to the variable hostName and output to the screen in the next command.
hostName=$(az webapp show --resource-group azuremolchapter20 --name $webAppName --query defaultHostName -o tsv)

# Now you can access the Web App in your web browser
echo "To see your IoT-connected Web App in action, enter the following address in to your web browser:" $hostName