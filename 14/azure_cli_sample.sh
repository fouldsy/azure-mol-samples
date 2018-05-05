# Create a resource group
az group create --name azuremolchapter14 --location eastus

# Create an Azure Storage account
# Enable Blob services encryption, and only permit HTTPS traffic
az storage account create \
	--name azuremolstorage \
	--resource-group azuremolchapter14 \
	--sku standard_lrs \
	--encryption-services blob \
	--https-only true

# Verify that the Storage account is configured encryption and HTTPS traffic
az storage account show \
    --name azuremolstorage \
	--resource-group azuremolchapter14 \
	--query [enableHttpsTrafficOnly,encryption]

# Create an Azure Key Vault
# Enable the vault for use with disk encryption
az keyvault create \
	--resource-group azuremolchapter14 \
	--name azuremolkeyvault \
	--enabled-for-disk-encryption

# Create a encryption key
# This key is stored in Key Vault and used to encrypt / decrypt VMs
# A basic software vault is used to store the key rather than premium Hardware Security Module (HSM) vault
# where all encrypt / decrypt operations are performed on the hardware device
az keyvault key create \
    --vault-name azuremolkeyvault \
    --name azuremolencryptionkey \
    --protection software

# Create an Azure Active Directory service principal
# A service principal is a special type of account in Azure Active Directory, seperate from regular user accounts
# This servie principal is used to request access to the encryption key from Key Vault
# Once the key is obtained from Key Vault, it can be used to encrypt / decrypt VMs 
az ad sp create-for-rbac
    --query “{spn_id:appId,secret:password}”

# Set permissions on Key Vault with policy
# The policy grants the service principal created in the previous step permissions to retrieve the key
az keyvault set-policy \
    --name azuremolkeyvault \
    --spn 4d1ab719-bd14-48fd-95d0-3aba9500b12f   \
    --key-permissions wrapKey   \
    --secret-permissions set

# Create a VM
az vm create \
    --resource-group azuremolchapter14 \
    --name molvm \
    --image ubuntults \
    --admin-username azuremol \
    --generate-ssh-keys

# Encrypt the VM created in the previous step
# The service principal, Key Vault, and encryption key created in the previous steps are used
az vm encryption enable \
    --resource-group azuremolchapter14 \
    --name molvm \
    --disk-encryption-keyvault azuremolkeyvault \
    --key-encryption-key azuremolencryptionkey \
    --aad-client-id 4d1ab719-bd14-48fd-95d0-3aba9500b12f \
    --aad-client-secret 2575580b-3610-46b2-b3db-182d8741fd43

# Monitor the encryption status
# When the status reports as VMRestartPending, the VM must be restarted to finalize encryption
az vm encryption show \
    --resource-group azuremolchapter14 \
    --name molvm