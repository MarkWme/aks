@description('Location')
param location string = resourceGroup().location

@description('Network number')
param networkNumber string

param kubernetesVersion string

param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param name string = 'aks-${uniqueString(uniqueSeed)}'

@description('Tags for resources')
param tags object = {
  env: 'Dev'
  dept: 'Ops'
}

module aksNetwork 'modules/network.bicep' = {
  name: '${deployment().name}--aksNetwork'
  params: {
    name: name
    location: location
    networkNumber: networkNumber
  }
}

module aksIdentity 'modules/identity.bicep' = {
  name: '${deployment().name}--aksIdentity'
  params: {
    name: name
    location: location
  }
}

module aksCluster 'modules/aks.bicep' = [for i in range(1, 2): {
  name: '${deployment().name}--aksCluster--${i}'
  params: {
    name: '${name}-${i}'
    location: location
    kubernetesVersion: kubernetesVersion
    nodeCount: 3
    nodeSubnetId: aksNetwork.outputs.nodeSubnetId
    podSubnetId: aksNetwork.outputs.podSubnetId
    identityId: aksIdentity.outputs.identityId
  }

  dependsOn: [
    aksNetwork
  ]
}]
