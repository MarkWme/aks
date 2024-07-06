@description('Region for the first cluster')
param primaryLocation string = resourceGroup().location

@description('Region for the second cluster')
param secondaryLocation string

var locations = [
  primaryLocation
  secondaryLocation
]

@description('Network number')
param networkNumber int

param clusterCount int = 3

param kubernetesVersion string

param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param name string = 'aks-${uniqueString(uniqueSeed)}'

@description('Tags for resources')
param tags object = {
  role: 'aks-fleet'
}

module aksFleet 'modules/fleet.bicep' = {
  name: '${deployment().name}--fleet'
  params: {
    name: '${name}-fm'
    location: primaryLocation
    tags: tags
  }
}

module location 'modules/location.bicep' = [for (l, i) in locations: {
  name: '${deployment().name}--location--${i}'
  params: {
    name: '${name}-${l}'
    location: l
    networkNumber: networkNumber + i
    kubernetesVersion: kubernetesVersion
    clusterCount: clusterCount
    fleetName: aksFleet.outputs.name
  }
}]
