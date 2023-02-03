param name string
param location string

resource aksFleet 'Microsoft.ContainerService/fleets@2022-09-02-preview' = {
  name: name
  location: location
  properties: {
    hubProfile: {
      dnsPrefix: name
    }
  }
}

output name string = aksFleet.name
