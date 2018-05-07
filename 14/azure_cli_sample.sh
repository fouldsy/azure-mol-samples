#!/bin/bash

# This script sample is part of "Learn Azure in a Month of Lunches" (Manning
# Publications) by Iain Foulds.
#
# This sample script covers the exercises from chapter 14 of the book. For more
# information and context to these commands, read a sample of the book and
# purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
#
# This script sample is released under the MIT license. For more information,
# see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

# Create a resource group
az group create --name azuremolchapter14 --location eastus

# Define a unique name for the Storage account
storageAccount=mystorageaccount$RANDOM

# Create an Azure Storage account
# Enable Blob services encryption, and only permit HTTPS traffic
az storage account create \
	--resource-group azuremolchapter14 \
	--name $storageAccount \
	--sku standard_lrs \
	--encryption-services blob \
	--https-only true

# Verify that the Storage account is configured encryption and HTTPS traffic
az storage account show \
    --name $storageAccount \
	--resource-group azuremolchapter14 \
	--query [enableHttpsTrafficOnly,encryption]

# Define a unique name for the Key Vault
keyVaultName=mykeyvault$RANDOM

# Create an Azure Key Vault
# Enable the vault for use with disk encryption
az keyvault create \
	--resource-group azuremolchapter14 \
	--name $keyVaultName \
	--enabled-for-disk-encryption

# Create a encryption key
# This key is stored in Key Vault and used to encrypt / decrypt VMs
# A basic software vault is used to store the key rather than premium Hardware Security Module (HSM) vault
# where all encrypt / decrypt operations are performed on the hardware device
az keyvault key create \
    --vault-name $keyVaultName \
    --name azuremolencryptionkey \
    --protection software

# Create an Azure Active Directory service principal
# A service principal is a special type of account in Azure Active Directory, seperate from regular user accounts
# This servie principal is used to request access to the encryption key from Key Vault
# Once the key is obtained from Key Vault, it can be used to encrypt / decrypt VMs 
read spnId secret <<< $(az ad sp create-for-rbac --query [appId,password] -o tsv)

# Set permissions on Key Vault with policy
# The policy grants the service principal created in the previous step permissions to retrieve the key
az keyvault set-policy \
    --name $keyVaultName \
    --spn $spnId   \
    --key-permissions wrapKey   \
    --secret-permissions set

# Create a VM
az vm create \
    --resource-group azuremolchapter14 \
    --name molvm \
    --image ubuntults \
    --admin-username azuremol \
    --generate-ssh-keys

# Encrypt the VM created in the previous step
# The service principal, Key Vault, and encryption key created in the previous steps are used
az vm encryption enable \
    --resource-group azuremolchapter14 \
    --name molvm \
    --disk-encryption-keyvault $keyVaultName \
    --key-encryption-key azuremolencryptionkey \
    --aad-client-id $spnId \
    --aad-client-secret $secret

# Monitor the encryption status
# When the status reports as VMRestartPending, the VM must be restarted to finalize encryption
az vm encryption show \
    --resource-group azuremolchapter14 \
    --name molvm