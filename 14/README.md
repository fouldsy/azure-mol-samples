This sample script creates an Azure Key Vault that is enabled for deployment. An Azure Active Directory service principal is created and permissions assigned to the Key Vault that allow it to access encryption keys.

A VM is then created and encrypted using the AAD service principal and encryption key stored in Key Vault.