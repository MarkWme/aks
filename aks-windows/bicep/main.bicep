@description('Location')
param location string = resourceGroup().location

@description('Network number')
param networkNumber string

param kubernetesVersion string

param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param name string = 'aks-${uniqueString(uniqueSeed)}'

param keyVaultName string
param keyVaultResourceGroup string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroup)
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
    podSubnetId: aksNetwork.outputs.podSubnetId
    identityId: aksIdentity.outputs.identityId
    adminUsername: keyVault.getSecret('winAdminUser')
    adminPassword: keyVault.getSecret('winAdminPassword')
  }

  dependsOn: [
    aksNetwork
  ]
}
