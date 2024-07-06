#!/bin/sh

# Set environment variables to hold values for the Azure subscription, resource group, AKS Fleet name and ID and current logged in user.
export subscriptionId=$(az account show --query id -o tsv)
export resourceGroup=$( az resource list --tag role=aks-fleet --query "[?contains(type, 'Microsoft.ContainerService/fleets')].resourceGroup" -o tsv)
export fleetName=$( az resource list --tag role=aks-fleet --query "[?contains(type, 'Microsoft.ContainerService/fleets')].name" -o tsv)
export fleetId=$( az resource list --tag role=aks-fleet --query "[?contains(type, 'Microsoft.ContainerService/fleets')].id" -o tsv)
export userId=$(az ad signed-in-user show --query "id" --output tsv)

# Get the kubeconfig for the AKS Fleet and set the current context to the AKS Fleet.
az fleet get-credentials --resource-group ${resourceGroup} --name ${fleetName}

# Create a role assignment for the current user to access the AKS Fleet.
az role assignment create --role "Azure Kubernetes Fleet Manager RBAC Cluster Admin" --assignee ${userId} --scope ${fleetId}

# This command will list the member clusters in the AKS Fleet.
kubectl get memberclusters
