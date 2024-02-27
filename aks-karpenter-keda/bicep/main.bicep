@description('Location')
param location string = resourceGroup().location

@description('Network number')
param networkNumber string

param kubernetesVersion string

param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param name string = 'aks-${uniqueString(uniqueSeed)}'

@description('Tags for resources')
param tags object = {
  keda: 'enabled'
  karpenter: 'enabled'
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

module aksCluster 'modules/aks.bicep' = {
  name: '${deployment().name}--aksCluster'
  params: {
    name: name
    location: location
    kubernetesVersion: kubernetesVersion
    nodeCount: 3
    nodeSubnetId: aksNetwork.outputs.nodeSubnetId
    identityId: aksIdentity.outputs.identityId
  }

  dependsOn: [
    aksNetwork
  ]
}
