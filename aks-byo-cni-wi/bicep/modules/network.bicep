param name string
param location string
param networkNumber string
param virtualNetworkCidr string = '10.${networkNumber}.0.0/16'
param nodeSubnetCidr string = '10.${networkNumber}.0.0/24'
param podSubnetCidr string = '10.${networkNumber}.1.0/24'

resource aksVirtualNetwork 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: '${name}-network'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkCidr
      ]
    }
    subnets: [
      {
        name: '${name}-node-subnet'
        properties: {
          addressPrefix: nodeSubnetCidr
        }
      }
      {
        name: '${name}-pod-subnet'
        properties: {
          addressPrefix: podSubnetCidr
        }
      }
    ]
  }
  resource nodeSubnet 'subnets' existing = {
    name: '${name}-node-subnet'
  }

  resource podSubnet 'subnets' existing = {
    name: '${name}-pod-subnet'
  }
}

output podSubnetId string = aksVirtualNetwork::podSubnet.id
output nodeSubnetId string = aksVirtualNetwork::nodeSubnet.id
