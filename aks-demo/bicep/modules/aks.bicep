param name string
param location string
param kubernetesVersion string
param nodeCount int
param nodeSubnetId string
param identityId string
param nodeSku string = 'Standard_D2s_v5'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-03-02-preview' = {
  name: name
  location: location
  sku: {
    name: 'Base'
    tier: 'Standard'
  }
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
      advancedNetworking: {
        observability: {
          enabled: true
        }
      }
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
      {
        name: 'wrk'
        count: nodeCount
        osType: 'Linux'
        osSKU: 'AzureLinux'
        type: 'VirtualMachineScaleSets'
        mode: 'User'
        vmSize: nodeSku
        orchestratorVersion: kubernetesVersion
        vnetSubnetID: nodeSubnetId
      }
    ]
    workloadAutoScalerProfile: {
      keda: {
        enabled: true
      }
      verticalPodAutoscaler: {
        addonAutoscaling: 'enabled'
        enabled: true
      }
    }
    metricsProfile: {
      costAnalysis: {
        enabled: true
      }
    }
  }
}
