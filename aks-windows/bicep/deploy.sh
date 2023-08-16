#!/bin/zsh

#
# AKS cluster
#
location=westeurope
keyVaultName=msazuredev
keyVaultResourceGroup=shared
#
# Choose random name for resources
#
name=aks-$(cat /dev/urandom | base64 | tr -dc '[:lower:]' | fold -w ${1:-5} | head -n 1) 2>/dev/null
#
# Calculate next available network address space
#
number=0
number=$(az network vnet list --query "[].addressSpace.addressPrefixes" -o tsv | cut -d . -f 2 | sort | tail -n 1)
if [[ -z $number ]]
then
    number=0
fi
networkNumber=$(expr $number + 1)
virtualNetworkPrefix=10.${networkNumber}.0.0/16
aksSubnetPrefix=10.${networkNumber}.0.0/24
#
# Get current latest (preview) version of Kubernetes
#
version=$(az aks get-versions -l $location | jq -r "(.values[].patchVersions) | keys | .[]" | sort | tail -n 1) 2>/dev/null

#
# Create resource group
#
az group create -n $name -l $location

az deployment group create \
    -n $name-$RANDOM \
    -g $name \
    -f ./main.bicep \
    --parameters \
        name=$name \
        networkNumber=$networkNumber \
        kubernetesVersion=$version \
        keyVaultName=$keyVaultName \
        keyVaultResourceGroup=$keyVaultResourceGroup \
    -o table

