#!/bin/zsh

export resourceGroup=$( az resource list --tag role=aks-fleet --query "[?contains(type, 'Microsoft.ContainerService/fleets')].resourceGroup" -o tsv)
export fleetName=$( az resource list --tag role=aks-fleet --query "[?contains(type, 'Microsoft.ContainerService/fleets')].name" -o tsv)

clusterNames=$(az fleet member list -g $resourceGroup -f $fleetName --query "[].name" -o tsv)

echo "$clusterNames" | while read clusterName; do
    if [ ! -z "$clusterName" ]; then
        echo "Processing cluster: $clusterName"
        az fleet member reconcile -g $resourceGroup -f $fleetName -n $clusterName
    fi
done