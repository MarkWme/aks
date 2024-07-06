param name string
param location string


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: '${name}-id'
  location: location
}

output identityId string = managedIdentity.id
