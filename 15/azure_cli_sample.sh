az group create --name azuremolchapter15 --location eastus

az keyvault create \
    --resource-group azuremolchapter15 \
    --name azuremol \
    --enable-soft-delete \
    --enabled-for-deployment

az keyvault secret set \
    --name databasepassword \
    --vault-name azuremol \
    --description "Database password" \
    --value "SecureP@ssw0rd"


az keyvault secret show \
    --name databasepassword \
    --vault-name azuremol

az keyvault secret delete \
    --name databasepassword \
    --vault-name azuremol

az keyvault secret recover \
    --name databasepassword \
    --vault-name azuremol

az vm create \
    --resource-group azuremolchapter15 \
    --name molvm \
    --image ubuntults \
    --admin-username azuremol \
    --generate-ssh-keys

scope=$(az group show --resource-group azuremolchapter15 --query id --output tsv)

read systemAssignedIdentity <<< $(az vm assign-identity \
    --resource-group azuremolchapter15 \
    --name molvm \
    --role reader \
    --scope $scope)

az ad sp list \
        --query "[?contains(objectId, 'f5994eeb-4be3-4cf5-83d2-552c6ccb0bed')]" | grep -A 3 servicePrincipalNames

az keyvault set-policy \
    --name azuremol \
    --secret-permissions get \
    --spn 887e9665-3c7d-4142-b9a3-c3b3346cd2e2
