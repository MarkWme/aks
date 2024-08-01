#!/bin/sh

# You may need to run the `api-access.sh` script in the `AccessFleetManagerK8sAPI` scenario before running this script. This will ensure that the necessary RBAC roles have been applied.

# Connect to the Fleet hub cluster

echo "Setting environment variables"
export resourceGroup=$(az resource list --resource-type Microsoft.ContainerService/fleets --query "[?contains(tags.role,'aks-fleet')].resourceGroup" -o tsv)
export fleetName=$(az resource list --resource-type Microsoft.ContainerService/fleets --query "[?contains(tags.role,'aks-fleet')].name" -o tsv)
export fleetId=$( az resource list --tag role=aks-fleet --query "[?contains(type, 'Microsoft.ContainerService/fleets')].id" -o tsv)
export userId=$(az ad signed-in-user show --query "id" --output tsv)

export acrName=msazuredev

echo "Getting credentials for the Fleet Manager hub cluster"
az fleet get-credentials --resource-group ${resourceGroup} --name ${fleetName} --overwrite-existing

echo "Creating role assignment for user $userId on fleet $fleetId"
az role assignment create --role "Azure Kubernetes Fleet Manager RBAC Cluster Admin" --assignee ${userId} --scope ${fleetId}

echo "Waiting for role assignment to propagate..."
sleep 30  

# Get the list of member clusters

clusterNames=$(kubectl get memberclusters -o='jsonpath'="{range .items[*].metadata }{.name}{'\n'}{end}")

# Iterate over each cluster and apply the ConfigMap

echo "$clusterNames" | while read clusterName; do
    if [ ! -z "$clusterName" ]; then
        echo "Getting cluster credentials for $clusterName"
        az aks get-credentials -g $resourceGroup -n $clusterName --overwrite-existing > /dev/null 2>&1
        echo "Attaching Azure Container Registry $acrName.azurecr.io to $clusterName"
        az aks update -g $resourceGroup -n $clusterName --attach-acr $acrName -o table > /dev/null 2>&1
        echo "Applying ConfigMap to $clusterName"
        # Apply the ConfigMap directly without a temporary file
        kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
    name: cluster-info
    namespace: kube-system
data:
    cluster-name: "$clusterName"
EOF
    fi
done

kubectl config use-context hub
