#!/bin/bash

# This script sample is part of "Learn Azure in a Month of Lunches" (Manning
# Publications) by Iain Foulds.
#
# This sample script covers the exercises from chapter 15 of the book. For more
# information and context to these commands, read a sample of the book and
# purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
#
# This script sample is released under the MIT license. For more information,
# see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

# Install jq JSON parser
sudo apt-get install -y jq

# Use the local MSI service to request an access token
access_token=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true --silent | jq -r '.access_token')

# Request the database password from Key Vault
database_password=$(curl https://$1.vault.azure.net/secrets/databasepassword?api-version=2016-10-01 -H "Authorization: Bearer $access_token" --silent | jq -r '.value')

# Assign the database passwoed obtained from Key Vault to debconf
# This step allows the database password to be automatically populated during the install
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $database_password"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $database_password"

# Install the MySQL server
sudo apt-get -y install mysql-server