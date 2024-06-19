param name string
param location string
param networkNumber int
param virtualNetworkCidr string = '10.${networkNumber}.0.0/16'
param clusterCount int

var podSubnetNames = [for i in range(1, clusterCount): '${name}-pod-subnet-${i}']
var subnetNames = concat(array('${name}-node-subnet'), podSubnetNames)
  
resource aksVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: '${name}-network'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkCidr
      ]
    }
    subnets: [ for i in range(0, clusterCount + 1) : {
      name: subnetNames[i]
      properties: {
        addressPrefix: '10.${networkNumber}.${i}.0/24'
      }
    }]
  }
  resource aksSubnets 'subnets' existing = [ for i in range(0, clusterCount + 1) : {
    name: subnetNames[i]
  }]
}

output nodeSubnetId string = aksVirtualNetwork::aksSubnets[0].id
output podSubnetIds array = [for i in range(1, clusterCount) : aksVirtualNetwork::aksSubnets[i].id]
