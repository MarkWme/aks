param name string
param location string
param tags object

resource aksFleet 'Microsoft.ContainerService/fleets@2024-02-02-preview' = {
  name: name
  location: location
  properties: {
    hubProfile: {
      dnsPrefix: name
    }
  }
  tags: tags
}

output name string = aksFleet.name
