param name string
param clusterId string
param group string

resource aksFleet 'Microsoft.ContainerService/fleets@2024-02-02-preview' existing = {
  name: name
}

resource aksFleetMembers 'Microsoft.ContainerService/fleets/members@2024-02-02-preview' = {
  parent: aksFleet
  name: substring(clusterId, lastIndexOf(clusterId, '/') + 1)
  properties: {
    clusterResourceId: clusterId
    group: group
  }
}

