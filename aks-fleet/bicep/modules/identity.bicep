param name string
param location string


resource aksIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: '${name}-id'
  location: location
}

output identityId string = aksIdentity.id
