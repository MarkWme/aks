param name string
param location string

resource aksFleet 'Microsoft.ContainerService/fleets@2024-04-01' = {
  name: name
  location: location
  properties: {
    hubProfile: {
      dnsPrefix: name
    }
  }
}

output name string = aksFleet.name
