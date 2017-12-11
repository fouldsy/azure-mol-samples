# Clone the Azure MOL sample repo, if you haven't already
git clone https://github.com/fouldsy/azure-mol-samples.git
cd azure-mol-samples/4

# Run the sample script to see Azure Storage Tables in action
# This script creates a Table, adds some data, and queries the data
# It's a basic example to show how NoSQL datastores work with Tables
python2.7 storage_table_demo.py

# Run the sample script to see Azure Storage Queues in action
# This script creates a Queue, adds some messages, then reads and process them
# It's a basic example to show how you can exchange messages between application
# components with Queues
python2.7 storage_queue_demo.py 

# To resize your VM for different storage needs, check which sizes are available
az vm list-sizes --location eastus --output table

# Create a resource group
az group create --name azuremolchapter4 –-location eastus

# Here, you can pick which VM to create:
# Option 1 - Create a Linux VM
# This option creates an Ubuntu Server LTS VM, then creates and connects a 64Gb data disk
az vm create \
    --resource-group azuremolchapter4 \
    --name storagevm \
    --image UbuntuLTS \
    --admin-username adminuser \
    --generate-ssh-keys \
    --data-disk-sizes-gb 64

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