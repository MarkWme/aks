@description('Specifies the name of the Azure Monitor managed service for Prometheus resource.')
param name string

@description('Specifies the name of the Azure Monitor managed service for Prometheus resource.')
param location string = resourceGroup().location

@description('Specifies the resource tags for the Azure Monitor managed service for Prometheus resource.')
param tags object

resource azureMonitorWorkspace 'Microsoft.Monitor/accounts@2023-04-03' = {
  name: name
  location: location
  tags: tags
}

output azureMonitorWorkspaceResourceId string = azureMonitorWorkspace.id
