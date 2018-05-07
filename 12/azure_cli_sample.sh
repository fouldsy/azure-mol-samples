#!/bin/bash

# This script sample is part of "Learn Azure in a Month of Lunches" (Manning
# Publications) by Iain Foulds.
#
# This sample script covers the exercises from chapter 12 of the book. For more
# information and context to these commands, read a sample of the book and
# purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
#
# This script sample is released under the MIT license. For more information,
# see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

# Create a resource group. This is a logical container to hold your resources.
# You can specify any name you wish, so long as it's unique with your Azure
# subscription and location
az group create --name azuremolchapter12 --location eastus

# Create a Linux VM
# You specify the resoure group from the previous step, then provide a name.
# This VM uses Ubuntu LTS as the VM image, and creates a user name `azuremol`
# The `--generate-ssh-keys` checks for keys you may have created earlier. If
# SSH keys are found, they are used. Otherwise, they are created for you
az vm create \
    --resource-group azuremolchapter12 \
    --name molvm \
    --image UbuntuLTS \
    --admin-username azuremol \
    --generate-ssh-keys

# Define a unique name for the Storage account
storageAccount=mystorageaccount$RANDOM

# Create a storage account for the diagnostics
# Both the boot diagnostics and VM diagnostics use an Azure Storage account to
# hold their logs data and stream metric data
az storage account create \
    --resource-group azuremolchapter12 \
    --name $storageAccount \
    --sku Standard_LRS

# Enable boot diagnostics on the VM
# The Storage account created in the previous step is used as the destination 
# for the boot diagnostics data
az vm boot-diagnostics enable \
    --resource-group azuremolchapter12 \
    --name molvm \
    --storage $(az storage account show \
        --resource-group azuremolchapter12 \
        --name $storageAccount \
        --query primaryEndpoints.blob \
        --output tsv)

# Obtain the ID of the VM
# To set the VM diagnostics, the ID is needed to reference the VM, not just name
vmId=$(az vm show \
    --resource-group azuremolchapter12 \
    --name molvm \
    --query "id" \
    --output tsv)

# Get the default diagnostics settings for what metrics to enable
# The Storage account and VM ID information is then added to this diagnostics
# variable to be applied to the VM in a following step
diagnosticsConfig=$(az vm diagnostics get-default-config \
                        | sed "s#__DIAGNOSTIC_STORAGE_ACCOUNT__#$storageAccount#g" \
                        | sed "s#__VM_OR_VMSS_RESOURCE_ID__#$vmId#g")

# Generate a Storage account token
# To allow the VM to stream metric data to the Storage account, you need to
# create an access token
storageToken=$(az storage account generate-sas \
                --account-name $storageAccount \
                --expiry 9999-12-31T23:59Z \
                --permissions wlacu \
                --resource-types co \
                --services bt \
                --output tsv)

# Define protected settings that contain the Storage account information
# As this setting contains the Storage account access token, the settings are
# protected to prevent the data being viewed during transmission            
protectedSettings="{'storageAccountName': '{$storageAccount}', \
    'storageAccountSasToken': '{$storageToken}'}"

# Finally, apply the diagnostics settings on the VM
az vm diagnostics set \
    --resource-group azuremolchapter12 \
    --vm-name molvm \
    --settings "$diagnosticsConfig" \
    --protected-settings "$protectedSettings"


az vm restart --resource-group azuremolchapter12 --name molvm