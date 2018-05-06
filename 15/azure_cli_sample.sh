az group create --name azuremolchapter15 --location eastus

# Define a unique name for the Key Vault
keyVaultName=mykeyvault$RANDOM

az keyvault create \
    --resource-group azuremolchapter15 \
    --name $keyVaultName \
    --enable-soft-delete \
    --enabled-for-deployment

az keyvault secret set \
    --name databasepassword \
    --vault-name $keyVaultName \
    --description "Database password" \
    --value "SecureP@ssw0rd"

az keyvault secret show \
    --name databasepassword \
    --vault-name $keyVaultName

az keyvault secret delete \
    --name databasepassword \
    --vault-name $keyVaultName

sleep 5

az keyvault secret recover \
    --name databasepassword \
    --vault-name $keyVaultName

az vm create \
    --resource-group azuremolchapter15 \
    --name molvm \
    --image ubuntults \
    --admin-username azuremol \
    --generate-ssh-keys

scope=$(az group show --resource-group azuremolchapter15 --query id --output tsv)

read systemAssignedIdentity <<< $(az vm identity assign \
    --resource-group azuremolchapter15 \
    --name molvm \
    --role reader \
    --scope $scope \
    --query systemAssignedIdentity \
    --output tsv)

spn=$(az ad sp list \
    --query "[?contains(objectId, '$systemAssignedIdentity')].servicePrincipalNames[0]" \
    --output tsv)

az keyvault set-policy \
    --name $keyVaultName \
    --secret-permissions get \
    --spn $spn

# Apply the Custom Script Extension
# The Custom Script Extension runs on the first VM to install NGINX, clone the samples repo, then
# copy the example web files to the required location
az vm extension set \
    --publisher Microsoft.Azure.Extensions \
    --version 2.0 \
    --name CustomScript \
    --resource-group azuremolchapter8 \
    --vm-name webvm1 \
    --settings '{"fileUris":["https://raw.githubusercontent.com/fouldsy/azure-mol-samples/cliscripts/15/install_mysql_server.sh"]}'
    --protected-settings '{"commandToExecute":"sh install_mysql_server.sh $keyVaultName"}'

