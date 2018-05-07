#!/bin/bash

# This script sample is part of "Learn Azure in a Month of Lunches" (Manning
# Publications) by Iain Foulds.
#
# This sample script covers the exercises from chapter 4 of the book. For more
# information and context to these commands, read a sample of the book and
# purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
#
# This script sample is released under the MIT license. For more information,
# see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

# To resize your VM for different storage needs, check which sizes are available
az vm list-sizes --location eastus --output table

# Create a resource group
az group create --name azuremolchapter4 --location eastus

# Here, you can pick which VM to create:
echo "Please choose what type of VM to create:"
echo "1. Linux"
echo "2. Windows"
echo -n "Enter 1 or 2: "
read os
case $os in
        1)
            echo "Creating Linux VM..."

            # Option 1 - Create a Linux VM
            # This option creates an Ubuntu Server LTS VM, then creates and connects a 64Gb data disk
            az vm create \
                --resource-group azuremolchapter4 \
                --name storagevm \
                --image UbuntuLTS \
                --admin-username adminuser \
                --generate-ssh-keys \
                --data-disk-sizes-gb 64
            ;;

        2)
            echo "Creating Windows VM..."

            # Option 2 - Create a Windows VM
            # This option creates a Windows Server 2016 Datacenter VM, then creates and connects
            # a 64Gb data disk
            az vm create \
                --resource-group azuremolchapter4 \
                --name storagevm \
                --image Win2016Datacenter \
                --admin-username adminuser \
                --admin-password P@ssw0rd!\
                --data-disk-sizes-gb 64
            ;;
        *) echo "Invalid input"
            ;;
esac

# Create and attach a data disk to your VM
# You can also use `az disk create` to create a disk without attaching it
# This example creates a 64Gb data disk and connects it to the VM
# Without the `--new` parameter, you could connect an existing disk
az vm disk attach \
    --resource-group azuremolchapter4 \
    --vm-name storagevm \
    --disk datadisk \
    --size-gb 64 \
    --sku Premium_LRS \
    --new