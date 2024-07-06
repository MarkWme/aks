@description('Location')
param location string = resourceGroup().location

param subscriptionId string = subscription().subscriptionId

param name string

param currentUserId string

@description('Tags for resources')
param tags object

module grafanaIdentity 'modules/identity.bicep' = {
  name: '${deployment().name}--grafanaIdentity'
  params: {
    name: name
    location: location
  }
}

module monitor 'modules/azureMonitorWorkspace.bicep' = {
  name: '${deployment().name}--azMonWks'
  params: {
    name: name
    location: location
    tags: tags
  }
}

module grafana 'modules/grafana.bicep' = {
  name: '${deployment().name}--grafana'
  params: {
    name: name
    location: location
    tags: tags
    identityId: grafanaIdentity.outputs.identityId
    azureMonitorWorkspaceResourceId: monitor.outputs.azureMonitorWorkspaceResourceId
    azureMonitorWorkspaceSubscriptionId: subscriptionId
    currentUserId: currentUserId
  }
}

module prometheus 'modules/prometheus.bicep' = {
  name: '${deployment().name}--prometheus'
  params: {
    azureMonitorWorkspaceResourceId: monitor.outputs.azureMonitorWorkspaceResourceId
    azureMonitorWorkspaceLocation: location
    clusterResourceId: '/subscriptions/0721201f-78df-41f1-9dad-adc0378bcc37/resourcegroups/aks-uarwl/providers/Microsoft.ContainerService/managedClusters/aks-uarwl'
    clusterLocation: location
    metricAnnotationsAllowList: ''
    metricLabelsAllowlist: ''
    enableWindowsRecordingRules: false
  }
}
