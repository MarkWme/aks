param name string
param location string
param kubernetesVersion string
param nodeCount int
param nodeSubnetId string
param podSubnetId string
param identityId string
@secure()
param adminUsername string
@secure()
param adminPassword string
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
    windowsProfile: {
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    agentPoolProfiles: [
      {
        name: 'sys'
        count: nodeCount
        osType: 'Linux'
        osSKU: 'Mariner'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        vmSize: nodeSku
        orchestratorVersion: kubernetesVersion
        vnetSubnetID: nodeSubnetId
        podSubnetID: podSubnetId
      }
      {
        name: 'win'
        count: nodeCount
        osType: 'Windows'
        osSKU: 'Windows2022'
        type: 'VirtualMachineScaleSets'
        mode: 'User'
        enableAutoScaling: false
        vmSize: nodeSku
        orchestratorVersion: kubernetesVersion
        vnetSubnetID: nodeSubnetId
        podSubnetID: podSubnetId
      }
    ]
  }
}
