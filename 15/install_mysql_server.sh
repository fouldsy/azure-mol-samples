# Instal jq JSON parser
sudo apt-get install -y jq

# Use the local MSI service to request an access token
access_token=$(curl http://localhost:50342/oauth2/token --data "resource=https://vault.azure.net" -H Metadata:true --silent | jq -r '.access_token')

# Request the database password from Key Vault
database_password=$(curl https://azuremol.vault.azure.1net/secrets/databasepassword?api-version=2016-10-01 -H "Authorization: Bearer $access_token" --silent | jq -r '.value')

# Assign the database passwoed obtained from Key Vault to debconf
# This step allows the database password to be automatically populated during the install
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $database_password"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $database_password"

# Install the MySQL server
sudo apt-get -y install mysql-server