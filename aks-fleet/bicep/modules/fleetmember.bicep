param name string
param clusterId string

resource aksFleet 'Microsoft.ContainerService/fleets@2022-09-02-preview' existing = {
  name: name
}

resource aksFleetMembers 'Microsoft.ContainerService/fleets/members@2022-09-02-preview' = {
  parent: aksFleet
  name: substring(clusterId, lastIndexOf(clusterId, '/') + 1)
  properties: {
    clusterResourceId: clusterId
  }
}

