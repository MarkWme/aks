#!/bin/sh

# Script to create a new AKS cluster (Standard) and add it to an existing Fleet

# Set environment variables
echo "Setting environment variables"
export subscriptionId=$(az account show --query id -o tsv)
export resourceGroup=$(az resource list --resource-type Microsoft.ContainerService/fleets --query "[?contains(tags.role,'aks-fleet')].resourceGroup" -o tsv)
export fleetName=$(az resource list --resource-type Microsoft.ContainerService/fleets --query "[?contains(tags.role,'aks-fleet')].name" -o tsv)
export fleetId=$(az resource list --tag role=aks-fleet --query "[?contains(type, 'Microsoft.containerservice/fleets')].id" -o tsv)
export userId=$(az ad signed-in-user show --query "id" --output tsv)
export location=$(az resource show --ids $fleetId --query location -o tsv)

# Set the name for the new AKS cluster
export clusterName="aks-member-$(date +%s | cut -c 6-10)"
# 'sudo apt install jq' if jq is not installed
export kubernetesVersion=$(az aks get-versions \
    --location ${location} \
    --query "values[?isPreview==null].patchVersions" -o json | jq -r 'map(to_entries | .[].key) | flatten | sort_by(. | split(".") | map(tonumber)) | last')
export vmSize="Standard_D2s_v3"
export nodeCount=3

echo "Creating new AKS cluster: $clusterName in resource group $resourceGroup with version $kubernetesVersion and size $vmSize. Node count: $nodeCount"
az aks create \
    --resource-group $resourceGroup \
    --name $clusterName \
    --location $location \
    --kubernetes-version $kubernetesVersion \
    --node-count $nodeCount \
    --node-vm-size $vmSize \
    --generate-ssh-keys \
    --tags "role=aks-fleet-member" \
    --output table

echo "Getting cluster credentials"
az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing

echo "Setting up Fleet access"
# Connect to the Fleet Manager hub cluster
echo "Getting Fleet credentials"
az fleet get-credentials --resource-group $resourceGroup --name $fleetName --overwrite-existing

echo "Creating role assignment for user $userId on fleet $fleetId"
az role assignment create --role "Azure Kubernetes Fleet Manager RBAC Cluster Admin" --assignee ${userId} --scope ${fleetId}

echo "Waiting for role assignment to propagate..."
sleep 30

# Add the new cluster as a member to the Fleet
echo "Adding $clusterName to fleet $fleetName"
az fleet member create \
    --resource-group $resourceGroup \
    --fleet-name $fleetName \
    --name $clusterName \
    --member-cluster-id $(az aks show -g $resourceGroup -n $clusterName --query id -o tsv)

echo "Waiting for cluster registration to propagate..."
sleep 30

# Verify that the member clusters successfully joined the Fleet resource.
echo "Verifying member clusters in the fleet"
az fleet member list --resource-group $resourceGroup --fleet-name $fleetName -o table

echo "Setup complete! New cluster $clusterName has been added to fleet $fleetName"
