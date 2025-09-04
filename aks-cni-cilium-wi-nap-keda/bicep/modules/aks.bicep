param name string
param location string
param kubernetesVersion string
param nodeCount int
param nodeSubnetId string
param identityId string
param nodeSku string = 'Standard_D2s_v5'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2025-03-02-preview' = {
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
    metricsProfile: {
      costAnalysis: {
        enabled: true
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
    ]
    nodeProvisioningProfile: {
      mode: 'Auto'
    }
    workloadAutoScalerProfile: {
      keda: {
        enabled: true
      }
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
     }
    oidcIssuerProfile: {
      enabled: true
    }
  }
  sku: {
    name: 'Base'
    tier: 'Standard'
  }

}
