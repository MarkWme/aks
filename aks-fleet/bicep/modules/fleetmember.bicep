param name string
param clusterId string

resource aksFleet 'Microsoft.ContainerService/fleets@2024-04-01' existing = {
  name: name
}

resource aksFleetMembers 'Microsoft.ContainerService/fleets/members@2024-04-01' = {
  parent: aksFleet
  name: substring(clusterId, lastIndexOf(clusterId, '/') + 1)
  properties: {
    clusterResourceId: clusterId
  }
}

