param name string
param location string
param kubernetesVersion string
param nodeCount int
param nodeSubnetId string
param identityId string
param nodeSku string = 'Standard_D2s_v3'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-09-02-preview' = {
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
      networkPluginMode: 'overlay'
      networkPolicy: 'cilium'
      networkDataplane: 'cilium'
      loadBalancerSku: 'standard'
      outboundType: 'loadBalancer'
      podCidr: '10.241.0.0/16'
      serviceCidr: '10.240.0.0/24'
      dnsServiceIP: '10.240.0.10'
    }
    agentPoolProfiles: [
      {
        name: 'system'
        count: nodeCount
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        vmSize: nodeSku
        osSKU: 'AzureLinux'
        orchestratorVersion: kubernetesVersion
        vnetSubnetID: nodeSubnetId
      }
    ]
    nodeProvisioningProfile: {
      mode: 'Auto'
    }
    workloadAutoScalerProfile: {
      keda: {
        enabled: true
      }
    }
  }
}
