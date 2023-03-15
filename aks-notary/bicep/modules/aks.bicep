param name string
param location string
param kubernetesVersion string
param nodeCount int
param nodeSubnetId string
param podSubnetId string
param identityId string
param nodeSku string = 'Standard_D2s_v3'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-09-01' = {
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
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      outboundType: 'loadBalancer'
      podCidr: podSubnetId
      serviceCidr: '10.240.0.0/24'
      dnsServiceIP: '10.240.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
    }
    agentPoolProfiles: [
      {
        name: 'system'
        count: nodeCount
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        vmSize: nodeSku
        osSKU: 'Mariner'
        orchestratorVersion: kubernetesVersion
        vnetSubnetID: nodeSubnetId
        podSubnetID: podSubnetId
      }
    ]
  }
}

output kubeletIdentityId string = aksCluster.properties.identityProfile.kubeletIdentity.objectId
