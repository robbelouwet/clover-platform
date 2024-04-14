param location string
param env string
param iteration string

var storageName = 'st${location}${env}d${iteration}'
var suffix = '${env}-${iteration}'
var vnetName = 'net-paper-dev-02' //'vnet-${suffix}'
var defaultSubnet = '10.0.0.0/24'
var zone = 'privatelink.file.core.windows.net'
var defaultSubnetName = 'sn-default-${suffix}'

// module vnetModule '../modules/network/virtual-network/main.bicep' = {
//   name: '${vnetName}-deployment'
//   params: {
//     name: vnetName
//     location: location
//     addressPrefixes: ['10.0.0.0/16']
//     subnets: [
//       {
//         name: defaultSubnetName
//         addressPrefix: defaultSubnet
//       }
//     ]
//   }
// }

module pdnsStorageAccModule '../modules/network/private-dns-zone/main.bicep' = {
  name: 'pdns-st-${suffix}-deployment'
  params: {
    name: zone
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: az.resourceId('Microsoft.Network/virtualNetworks', 'vnet-paper-dev-02') //vnetModule.outputs.resourceId
      }
    ]
  }
}

module storageModule '../modules/storage/storage-account/main.bicep' = {
  name: '${storageName}-deployment'
  params: {
    name: storageName
    location: location
    supportsHttpsTrafficOnly: false
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    publicNetworkAccess: 'Enabled'
    privateEndpoints: [
      {
        name: 'pe-st-${suffix}'
        service: 'file'
        subnetResourceId: az.resourceId(
          subscription().subscriptionId,
          resourceGroup().name,
          'Microsoft.Network/virtualNetworks/subnets',
          'vnet-paper-dev-02',
          //vnetModule.outputs.name,
          'sn-default-paper-dev-02' //defaultSubnetName
        )
        privateDnsZoneGroupName: zone
        privateDnsZoneResourceIds: [
          pdnsStorageAccModule.outputs.resourceId
        ]
      }
    ]
  }
}
