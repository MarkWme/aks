#!/bin/zsh

name=aks-qinmo
spotPrefix=spt

nodeResourceGroup=$(az aks show -n $name -g $name --query nodeResourceGroup -o tsv)

spotScaleSet=$(az vmss list --query "[?resourceGroup=='${nodeResourceGroup:u}'] | [?contains(name,'${spotPrefix}')].name" -o tsv)
instanceId=$(az vmss list-instances -g $nodeResourceGroup -n $spotScaleSet --query "[0].id" -o tsv)

az rest --method post --url https://management.azure.com${instanceId}/simulateEviction\?api-version\=2020-06-01

echo "Eviction request sent: $(date)"

