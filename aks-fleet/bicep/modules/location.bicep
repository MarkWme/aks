param name string
param location string
param networkNumber int
param kubernetesVersion string
param clusterCount int
param fleetName string

module aksNetwork 'network.bicep' = {
  name: '${deployment().name}--aksNetwork'
  params: {
    name: name
    location: location
    networkNumber: networkNumber
    clusterCount: clusterCount
  }
}

module aksIdentity 'identity.bicep' = [for i in range(1, clusterCount) : {
  name: '${deployment().name}--aksIdentity--${i}'
  params: {
    name: '${name}-${i}'
    location: location
  }
}]

module aksCluster 'aks.bicep' = [for i in range(1, clusterCount): {
  name: '${deployment().name}--aksCluster--${i}'
  params: {
    name: '${name}-${i}'
    location: location
    kubernetesVersion: kubernetesVersion
    nodeCount: 3
    nodeSubnetId: aksNetwork.outputs.nodeSubnetId
    podSubnetId: aksNetwork.outputs.podSubnetIds[i-1]
    identityId: aksIdentity[i-1].outputs.identityId
    fleetName: fleetName
  }

  dependsOn: [
    aksNetwork
  ]
}]
