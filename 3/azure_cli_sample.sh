# Create a resource group
az group create --name azuremolchapter3 --location eastus

# Create an App Service plan
# An App Service plan defines the location and available features
# These features include deployment slots, traffic routing options, and
# security options
az appservice plan create \
    --resource-group azuremolchapter3 \
    --name appservice \
    --sku S1

# Create a Web App in the App Service plan enabled for local Git deployments
# The Web App is what actually runs your web site, lets you create deployment
# slots, stream logs, etc.
az webapp create \
    --resource-group azuremolchapter3 \
    --name webappmol \
    --plan appservice \
    --deployment-local-git

# Create a Git user accout and set credentials
# Deployment users are used to authenticate with the App Service when you
# upload your web application to Azure
az webapp deployment user set \
    --user-name azuremol \
    --password M0lPassword!

# Clone the Azure MOL sample repo, if you haven't already
git clone https://github.com/fouldsy/azure-mol-samples.git
cd azure-mol-samples/3/prod

# Initialize the directory for use with Git, add the sample files, and commit
git init && git add . && git commit -m “Pizza”

# Add your Web App as a remote destination in Git
git remote add azure $(az webapp deployment source config-local-git \
    --resource-group azuremolchapter3 \
    --name webappmol -o tsv)

# Push, or upload, the sample app to your Web App
git push azure master