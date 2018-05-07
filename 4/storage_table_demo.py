# This script sample is part of "Learn Azure in a Month of Lunches" (Manning
# Publications) by Iain Foulds.
#
# This sample script covers the exercises from chapter 4 of the book. For more
# information and context to these commands, read a sample of the book and
# purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
#
# This script sample is released under the MIT license. For more information,
# see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

import string,random,time,azurerm,json,subprocess

from azure.cosmosdb.table.tableservice import TableService
from azure.cosmosdb.table.models import Entity

# Define variables to handle Azure authentication
get_token_cli = subprocess.Popen(['az account get-access-token | jq  -r .accessToken'], stdout=subprocess.PIPE, shell=True)
auth_token = str(get_token_cli.communicate()[0]).rstrip()
subscription_id = azurerm.get_subscription_from_cli()

# Define variables with random resource group and storage account names
resourcegroup_name = 'azuremol'+''.join(random.choice(string.ascii_lowercase + string.digits) for _ in range(6))
storageaccount_name = 'azuremol'+''.join(random.choice(string.ascii_lowercase + string.digits) for _ in range(6))
location = 'eastus'

###
# Create the a resource group for our demo
# We need a resource group and a storage account. A random name is generated, as each storage account name must be globally unique.
###
response = azurerm.create_resource_group(auth_token, subscription_id, resourcegroup_name, location)
if response.status_code == 200 or response.status_code == 201:
    print('Resource group: ' + resourcegroup_name + ' created successfully.')
else:
    print('Error creating resource group')

# Create a storage account for our demo
response = azurerm.create_storage_account(auth_token, subscription_id, resourcegroup_name, storageaccount_name,  location, storage_type='Standard_LRS')
if response.status_code == 202:
    print('Storage account: ' + storageaccount_name + ' created successfully.')
    print('\nWaiting for storage account to be ready before we create a Table')
    time.sleep(15)
else:
    print('Error creating storage account')


###
# Use the Azure Storage Storage SDK for Python to create a Table
###
print('\nLet\'s create an Azure Storage Table to store some data.')
raw_input('Press Enter to continue...')

# Each storage account has a primary and secondary access key.
# These keys are used by aplications to access data in your storage account, such as Tables.
# Obtain the primary storage access key for use with the rest of the demo

response = azurerm.get_storage_account_keys(auth_token, subscription_id, resourcegroup_name, storageaccount_name)
storageaccount_keys = json.loads(response.text)
storageaccount_primarykey = storageaccount_keys['keys'][0]['value']

# Create the Table with the Azure Storage SDK and the access key obtained in the previous step
table_service = TableService(account_name=storageaccount_name, account_key=storageaccount_primarykey)
response = table_service.create_table('pizzatable')
if response == True:
    print('Storage Table: pizzatable created successfully.\n')
else:
    print('Error creating Storage Table.\n')

time.sleep(1)


###
# Use the Azure Storage Storage SDK for Python to create some entries in the Table
###
print('Now let\'s add some entries to our Table.\nRemember, Azure Storage Tables is a NoSQL datastore, so this is similar to adding records to a database.')
raw_input('Press Enter to continue...')

# Each entry in a Table is called an 'entity'. 
# Here, we add an entry for first pizza with two pieces of data - the name, and the cost
#
# A partition key tracks how like-minded entries in the Table are created and queried.
# A row key is a unique ID for each entity in the partition
# These two properties are used as a primary key to index the Table. This makes queries much quicker.

pizza = Entity()
pizza.PartitionKey = 'pizzamenu'
pizza.RowKey = '001'
pizza.description = 'Pepperoni'
pizza.cost = 18
table_service.insert_entity('pizzatable', pizza)
print('Created entry for pepperoni...')

pizza = Entity()
pizza.PartitionKey = 'pizzamenu'
pizza.RowKey = '002'
pizza.description = 'Veggie'
pizza.cost = 15
table_service.insert_entity('pizzatable', pizza)
print('Created entry for veggie...')

pizza = Entity()
pizza.PartitionKey = 'pizzamenu'
pizza.RowKey = '003'
pizza.description = 'Hawaiian'
pizza.cost = 12
table_service.insert_entity('pizzatable', pizza)
print('Created entry for Hawaiian...\n')

time.sleep(1)


###
# Use the Azure Storage Storage SDK for Python to query for entities in our Table
###
print('With some data in our Azure Storage Table, we can query the data.\nLet\'s see what the pizza menu looks like.')
raw_input('Press Enter to continue...')

# In this query, you define the partition key to search within, and then which properties to retrieve
# Structuring queries like this improves performance as your application scales up and keeps the queries efficient
pizzas = table_service.query_entities('pizzatable', filter="PartitionKey eq 'pizzamenu'", select='description,cost')
for pizza in pizzas:
    print('Name: ' + pizza.description)
    print('Cost: ' + str(pizza.cost) + '\n')

time.sleep(1)


###
# This was a quick demo to see Tables in action.
# Although the actual cost is minimal (fractions of a cent per month) for the three entities we created, it's good to clean up resources when you're done
###
print('\nThis is a basic example of how Azure Storage Tables behave like a database.\nTo keep things tidy, let\'s clean up the Azure Storage resources we created.')
raw_input('Press Enter to continue...')

response = table_service.delete_table('pizzatable')
if response == True:
    print('Storage table: pizzatable deleted successfully.')
else:
    print('Error deleting Storage Table')

response = azurerm.delete_resource_group(auth_token, subscription_id, resourcegroup_name)
if response.status_code == 202:
    print('Resource group: ' + resourcegroup_name + ' deleted successfully.')
else:
    print('Error deleting resource group.')
