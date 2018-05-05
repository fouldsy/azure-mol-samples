# Create a resource group
az group create --name azuremolchapter9 --location westeurope

# Create an App Service plan
# A Standard SKU plan is created for general use
az appservice plan create \
  --name appservicemol \
  --resource-group azuremolchapter9 \
  --sku s1

# Create a Web App
# The Web App uses the App Service plan created in the previous step
# To deploy your application, the Web App is configured to use Git
az webapp create \
--name webappmol \
--resource-group azuremolchapter9 \
--plan appservicemol \
--deployment-local-git

# Add Web App autoscale?

# Change to the root of the chapter 9 samples directory
cd azure-mol-samples/9

# Initialize a basic Git repo for the web application
git init && git add . && git commit -m “Pizza”

# Add the Web App repo for Git deployments
git remote add webappmolscale <your-git-clone-url>

# Push the sample web application to your Web App
git push webappmolscale master