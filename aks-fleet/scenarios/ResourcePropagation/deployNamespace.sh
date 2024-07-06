export resourceGroup=$(az resource list --resource-type Microsoft.ContainerService/fleets --query "[?contains(tags.role,'aks-fleet')].resourceGroup" -o tsv)
export fleetName=$(az resource list --resource-type Microsoft.ContainerService/fleets --query "[?contains(tags.role,'aks-fleet')].name" -o tsv)
az fleet get-credentials --resource-group ${resourceGroup} --name ${fleetName} --overwrite-existing
kubectl apply -f namespace.yaml

kubectl apply -f namespaceplacement.yaml