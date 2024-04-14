param clusterName string
param suffix string
param storageName string
param cappEnvName string
param location string = resourceGroup().location

@secure()
param velocitySecret string

var cappEnvSubnetName = 'sn-env-${clusterName}-${suffix}'
var defaultSubnetName = 'sn-default-${clusterName}-${suffix}'
var vnetName = 'vnet-${clusterName}-${suffix}'
var workspaceName = 'law-${clusterName}-${suffix}'

var vnetCidr = '10.0.0.0/16'
var dockerBridgeCidr = '10.2.0.1/16'
var platformReservedCidr = '10.1.0.0/16'
var platformReservedDnsIP = '10.1.0.2'
var defaultSubnet = '10.0.0.0/24'
var cappEnvSubnet = '10.0.2.0/23'

// module vnetModule '../../modules/network/virtual-network/main.bicep' = {
//   name: '${clusterName}-vnet-deployment'
//   params: {
//     name: vnetName
//     location: location
//     addressPrefixes: [vnetCidr]
//     subnets: [
//       {
//         name: cappEnvSubnetName
//         addressPrefix: cappEnvSubnet
//       }
//       {
//         name: defaultSubnetName
//         addressPrefix: defaultSubnet
//       }
//     ]
//   }
// }

// module pdnsStorageAccModule '../../modules/network/private-dns-zone/main.bicep' = {
//   name: '${clusterName}-storage-acc-pds-deployment'
//   params: {
//     name: 'privatelink.file.core.windows.net'
//     location: 'global'
//     virtualNetworkLinks: [
//       {
//         virtualNetworkResourceId: vnetModule.outputs.resourceId
//       }
//     ]
//   }
// }

// resource workspaceResource 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
//   name: workspaceName
//   location: location
// }

module appModule 'app.bicep' = {
  name: '${clusterName}-app-${suffix}-deployment'
  params: {
    clusterName: clusterName
    cappEnvName: 'paper-capp-env-dev-02' //cappEnvName
    velocitySecret: velocitySecret
    cappEnvSubnetName: 'sn-env-paper-dev-02' //cappEnvSubnetName
    suffix: suffix
    storageName: storageName
    vnetName: 'vnet-paper-dev-02' // vnetModule.outputs.name

    workspaceName: 'law-paper-dev-02' //workspaceModule.outputs.name
    dockerBridgeCidr: dockerBridgeCidr
    platformReservedCidr: platformReservedCidr
    platformReservedDnsIP: platformReservedDnsIP
  }
}
