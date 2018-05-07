# This script sample is part of "Learn Azure in a Month of Lunches" (Manning
# Publications) by Iain Foulds.
#
# This sample script covers the exercises from chapter 10 of the book. For more
# information and context to these commands, read a sample of the book and
# purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
#
# This script sample is released under the MIT license. For more information,
# see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

import string,random,time,azurerm,json
import pydocumentdb
import pydocumentdb.document_client as document_client

# Define variables to handle Azure authentication
auth_token = azurerm.get_access_token_from_cli()
subscription_id = azurerm.get_subscription_from_cli()

# Define variables with random resource group and Cosmos DB account names
resourcegroup_name = 'azuremol'+''.join(random.choice(string.ascii_lowercase + string.digits) for _ in range(6))
cosmosdb_name = 'azuremol'+''.join(random.choice(string.ascii_lowercase + string.digits) for _ in range(6))
location = 'eastus'

###
# Create the a resource group for our demo
# We need a resource group and a Cosmos DB account. A random name is generated, as each Cosmos DB account name must be globally unique.
###
response = azurerm.create_resource_group(auth_token, subscription_id, resourcegroup_name, location)
if response.status_code == 200 or response.status_code == 201:
    print('Resource group: ' + resourcegroup_name + ' created successfully.')
else:
    print('Error creating resource group')

# Create a Cosmos DB account for our demo
response = azurerm.create_cosmosdb_account(auth_token, subscription_id, resourcegroup_name, cosmosdb_name, location, cosmosdb_kind='GlobalDocumentDB')
if response.status_code == 200:
    print('Cosmos DB account: ' + cosmosdb_name + ' created successfully.')
    print('\nIt can take a couple of minutes to get the Cosmos DB account ready. Waiting...')
    time.sleep(150)
else:
    print('Error creating Cosmos DB account: ' + str(response))

# Each Cosmos DB account has a primary and secondary access key.
# These keys are used by aplications to access data in your Cosmos DB account.
# Obtain the primary access key for use with the rest of the demo
response = azurerm.get_cosmosdb_account_keys(auth_token, subscription_id, resourcegroup_name, cosmosdb_name)
cosmosdb_keys = json.loads(response.text)
cosmosdb_primarykey = cosmosdb_keys['primaryMasterKey']

# Create a client for our Cosmos DB account
client = document_client.DocumentClient('https://' + cosmosdb_name + '.documents.azure.com', {'masterKey': cosmosdb_primarykey})

# Create a database for our pizzas using the Cosmos DB client created in the previous step
db = client.CreateDatabase({ 'id': 'pizzadb' })


time.sleep(1)


###
# Use the Azure Cosmos DB SDK for Python to create a collection in the database
###
print('\nNow let\'s create a collection in the database. We can store information about the pizzas our store sells.')
raw_input('Press Enter to continue...')

options = {
    'offerEnableRUPerMinuteThroughput': True,
    'offerVersion': "V2",
    'offerThroughput': 400
}

# A collection is used to store all your documents. Cosmos DB manages how the collection(s) are distributed for
# optimal performance. As the collection(s) are distributed, your app is unaware of the Cosmos DB back-end
# actions and management. You just add, edit, delete, or query your data.
collection = client.CreateCollection(db['_self'], { 'id': 'pizzas' }, options)


time.sleep(1)


###
# Use the Azure Cosmos DB SDK for Python to create some documents in the database
###
print('\nNow let\'s add some documents to our database.')
raw_input('Press Enter to continue...')


# Each document contains two properties - the description and cost of each pizza.
# After our documents are added, we query the database. Even though we only add two properties here, our
# final query returns properties that our document store uses to track data.
document1 = client.CreateDocument(collection['_self'],
    { 
        'description': 'Pepperoni',
        'cost': 18,
    })
document2 = client.CreateDocument(collection['_self'],
    { 
        'description': 'Veggie',
        'cost': 15,
    })
document3 = client.CreateDocument(collection['_self'],
    { 
        'description': 'Hawaiian',
        'cost': 12,
    })


time.sleep(1)


###
# Use the Azure Cosmos DB SDK for Python to query for documents in our database
###
print('\nWith some documents in our Cosmos DB database, we can query the data.\nLet\'s see what the pizza menu looks like.')
raw_input('Press Enter to continue...')

# If you've used SQL before, this structure looks familiar. You can create more complex queries as your app grows.
# For now, let's query for the pizza description and cost. You can use the 'Document explorer' in the Azure portal for you
# Cosmos DB database to see all the properties each document contains.
query = { 'query': 'SELECT pizza.description,pizza.cost FROM pizza' }    

# Pass the query through the SDK, then return and print the results.
pizzas = client.QueryDocuments(collection['_self'], query, options)
results = list(pizzas)

print(results)

time.sleep(3)


###
# Output connection info for Cosmos DB database.
# This information is needed for the sample web app that connects to the Cosmos DB database instance
###
print('\n\nTo connect to this Cosmos DB database from the sample web app in the next section, use the following connection info:')
print('\nconfig.endpoint = "https://' + cosmosdb_name + '.documents.azure.com";')
print('config.primaryKey = "' + cosmosdb_primarykey + '";')

time.sleep(1)
