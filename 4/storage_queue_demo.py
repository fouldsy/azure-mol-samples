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
from azure.storage.queue import QueueService

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
    print('\nWaiting for storage account to be ready before we create a Queue')
    time.sleep(15)
else:
    print('Error creating storage account')


###
# Use the Azure Storage Storage SDK for Python to create a Queue
###
print('\nLet\'s create an Azure Storage Queue to drop some messages on.')
raw_input('Press Enter to continue...')

# Each storage account has a primary and secondary access key.
# These keys are used by aplications to access data in your storage account, such as Queues.
# Obtain the primary storage access key for use with the rest of the demo

response = azurerm.get_storage_account_keys(auth_token, subscription_id, resourcegroup_name, storageaccount_name)
storageaccount_keys = json.loads(response.text)
storageaccount_primarykey = storageaccount_keys['keys'][0]['value']

# Create the Queue with the Azure Storage SDK and the access key obtained in the previous step
queue_service = QueueService(account_name=storageaccount_name, account_key=storageaccount_primarykey)
response = queue_service.create_queue('pizzaqueue')
if response == True:
    print('Storage Queue: pizzaqueue created successfully.\n')
else:
    print('Error creating Storage Queue.\n')


###
# Use the Azure Storage Storage SDK for Python to drop some messages in our Queue
###
print('Now let\'s drop some messages in our Queue.\nThese messages could indicate a take-out order being received for a customer ordering pizza.')
raw_input('Press Enter to continue...')

# This basic example creates a message for each pizza ordered. The message is *put* on the Queue.
queue_service.put_message('pizzaqueue', u'Veggie pizza ordered.')
queue_service.put_message('pizzaqueue', u'Pepperoni pizza ordered.')
queue_service.put_message('pizzaqueue', u'Hawiian pizza ordered.')
queue_service.put_message('pizzaqueue', u'Pepperoni pizza ordered.')
queue_service.put_message('pizzaqueue', u'Pepperoni pizza ordered.')


time.sleep(1)


###
# Use the Azure Storage Storage SDK for Python to count how many messages are in the Queue
###
print('\nLet\'s see how many orders we have to start cooking! Here, we simply examine how many messages are sitting the Queue. ')
raw_input('Press Enter to continue...')

metadata = queue_service.get_queue_metadata('pizzaqueue')
print('Number of messages in the queue: ' + str(metadata.approximate_message_count))


time.sleep(1)


###
# Use the Azure Storage Storage SDK for Python to read each message from the Queue
###
print('\nWith some messages in our Azure Storage Queue, let\'s read the first message in the Queue to signal we start to process that customer\'s order.')
raw_input('Press Enter to continue...')

# When you get each message, they become hidden from other parts of the applications being able to see it.
# Once you have successfully processed the message, you then delete the message from the Queue.
# This behavior makes sure that if something goes wrong in the processing of the message, it is then dropped back in the Queue for processing in the next cycle.
messages = queue_service.get_messages('pizzaqueue')
for message in messages:
    print('\n' + message.content)
    queue_service.delete_message('pizzaqueue', message.id, message.pop_receipt)

raw_input('\nPress Enter to continue...')
metadata = queue_service.get_queue_metadata('pizzaqueue')

print('If we look at the Queue again, we have one less message to show we have processed that order and a yummy pizza will be on it\'s way to the customer soon.')
print('Number of messages in the queue: ' + str(metadata.approximate_message_count))
raw_input('\nPress Enter to continue...')


###
# This was a quick demo to see Queues in action.
# Although the actual cost is minimal since we deleted all the messages from the Queue, it's good to clean up resources when you're done
###
print('\nThis is a basic example of how Azure Storage Queues behave.\nTo keep things tidy, let\'s clean up the Azure Storage resources we created.')
raw_input('Press Enter to continue...')

response = queue_service.delete_queue('pizzaqueue')
if response == True:
    print('Storage Queue: pizzaqueue deleted successfully.')
else:
    print('Error deleting Storage Queue')

response = azurerm.delete_resource_group(auth_token, subscription_id, resourcegroup_name)
if response.status_code == 202:
    print('Resource group: ' + resourcegroup_name + ' deleted successfully.')
else:
    print('Error deleting resource group.')
