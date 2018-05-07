#!/bin/bash

# This script sample is part of "Learn Azure in a Month of Lunches" (Manning
# Publications) by Iain Foulds.
#
# This sample script covers the exercises from chapter 13 of the book. For more
# information and context to these commands, read a sample of the book and
# purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
#
# This script sample is released under the MIT license. For more information,
# see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

# Create a resource group. This is a logical container to hold your resources.
# You can specify any name you wish, so long as it's unique with your Azure
# subscription and location
az group create --name azuremolchapter13 --location eastus

# Create a Linux VM
# You specify the resoure group from the previous step, then provide a name.
# This VM uses Ubuntu LTS as the VM image, and creates a user name `azuremol`
# The `--generate-ssh-keys` checks for keys you may have created earlier. If
# SSH keys are found, they are used. Otherwise, they are created for you
az vm create \
    --resource-group azuremolchapter13 \
    --name molvm \
    --image UbuntuLTS \
    --admin-username azuremol \
    --generate-ssh-keys

# Create a Recovery Services vault
# This vault is used to store your backups
az backup vault create \
    --resource-group azuremolchapter13 \
    --name molvault \
    --location eastus

# Enable backup for the VM
# The Recovery Services vault created in the previous step is used as the
# destination for the VM backup data
# The default backup policy for retention is also then applied
az backup protection enable-for-vm \
    --resource-group azuremolchapter13 \
    --vm molvm \
    --vault-name molvault \
    --policy-name DefaultPolicy

# Start a backup job for the VM
# The data is formatted into the d-m-Y format and is retained for 30 days
az backup protection backup-now \
    --resource-group azuremolchapter13 \
    --item-name molvm \
    --vault-name molvault \
    --container-name molvm \
    --retain-until $(date +%d-%m-%Y -d "+30 days")

# List the backup jobs
# The status of the backup should be listed as InProgress. It can 15-20 minutes
# for the initial backup job to complete
az backup job list \
    --resource-group azuremolchapter13 \
    --vault-name molvault \
    --output table