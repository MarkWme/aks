#!/bin/zsh

location=uksouth
#
# Choose random name for resources
#
name=aks-$(cat /dev/urandom | base64 | tr -dc '[:lower:]' | fold -w ${1:-5} | head -n 1) 2> /dev/null
name=promgraf
currentUserId=$(az ad signed-in-user show --query id -o tsv)
az group create -n $name -l $location -o table

az deployment group create \
    -n $name-$RANDOM \
    -g $name \
    -f ./main.bicep \
    --parameters \
        name=$name \
        currentUserId=$currentUserId \
        tags='{"key1":"value1", "key2":"value2"}' \
    -o table
