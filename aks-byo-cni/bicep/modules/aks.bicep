param name string
param location string
param kubernetesVersion string
param nodeCount int
param nodeSubnetId string
param identityId string
param nodeSku string = 'Standard_D2s_v5'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: true
    dnsPrefix: name
    networkProfile: {
      networkPlugin: 'none'
    }
    agentPoolProfiles: [
      {
        name: 'sys'
        count: nodeCount
        osType: 'Linux'
        osSKU: 'AzureLinux'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        vmSize: nodeSku
        orchestratorVersion: kubernetesVersion
        vnetSubnetID: nodeSubnetId
      }
    ]
  securityProfile: {
    workloadIdentity: {
      enabled: true
      }
    }
  oidcIssuerProfile: {
    enabled: true
    }
  }
}
