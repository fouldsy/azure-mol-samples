#!/bin/bash

# This script sample is part of "Learn Azure in a Month of Lunches" (Manning
# Publications) by Iain Foulds.
#
# This sample script covers the exercises from chapter 19 of the book. For more
# information and context to these commands, read a sample of the book and
# purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
#
# This script sample is released under the MIT license. For more information,
# see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

# Create a resource group
az group create --name azuremolchapter19 --location westeurope

# Create an Azure Container Instance
# A public image from Dockerhub is used as the source image for the container,
# and a public IP address is assigned. To allow web traffic to reach the 
# container instance, port 80 is also opened
az container create \
    --resource-group azuremolchapter19 \
    --name azuremol \
    --image iainfoulds/azuremol \
    --ip-address public \
    --ports 80

# Show the container instance public IP address
az container show \
    --resource-group azuremolchapter19 \
    --name azuremol \
    --query ipAddress.ip \
    --output tsv

# Create an Azure Container Service with Kubernetes (AKS) cluster
# Two nodes are created. It can take 15-20 minutes for this operation to
# successfully complete.
az aks create \
    --resource-group azuremolchapter19 \
    --name azuremol \
    --node-count 2 \
    --generate-ssh-keys

# Get the AKS credentials
# This gets the Kuebernetes connection information and applies to a local
# config file. You can then use native Kubernetes tools to connect to the
# cluster.
az aks get-credentials \
    --resource-group azuremolchapter19 \
    --name azuremol

# Start an Kubernetes deployment
# This deployment uses the same base container image as the ACI instance in
# a previous example. Again, port 80 is opened to allow web traffic.
kubectl run azuremol \
    --image=docker.io/iainfoulds/azuremol:latest \
    --port=80

# Create a load balancer for Kubernetes deployment
# Although port 80 is open to the deployment, external traffic can't reach the
# Kubernetes pods that run the containers. A load balancer needs to be created
# that maps external traffic on port 80 to the pods. Although this is a
# Kubernetes command, kubectl, under the hood an Azure load balancer and rules
# are created
kubectl expose deployment/azuremol \
    --type="LoadBalancer" \
    --port 80

# Scale out the number of nodes in the AKS cluster
# The cluster is scaled up to 3 nodes
az aks scale \
    --resource-group azuremolchapter19 \
    --name azuremol \
    --node-count 3

# Scale up the number of replicas
# When our web app container was deployed, only one instance was created. Scale
# up to 5 instances, distributed across all three nodes in the cluster
kubectl scale deployment azuremol --replicas 5

