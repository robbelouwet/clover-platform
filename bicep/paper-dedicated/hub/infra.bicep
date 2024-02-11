param appName string
param suffix string
param location string
param workspaceName string
param storageName string
param vnetName string
param cappEnvSubnetName string
param cosmosDbAccountName string
param cosmosDbDatabaseName string
param cosmosDbContainerName string

var defaultSubnetName = 'sn-default-${appName}-${suffix}'
var defaultSubnet = '10.0.0.0/24'
var cappEnvSubnet = '10.0.2.0/23'

module vnetModule '../../modules/network/virtual-network/main.bicep' = {
  name: '${vnetName}-deployment'
  params: {
    name: vnetName
    location: location
    addressPrefixes: [ '10.0.0.0/16' ]
    subnets: [
      {
        name: defaultSubnetName
        addressPrefix: defaultSubnet
      }
      {
        name: cappEnvSubnetName
        addressPrefix: cappEnvSubnet
      }
    ]
  }
}

resource cosmosdb 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: cosmosDbAccountName
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
      }
    ]
  }

  resource cosmosDbDatabase 'sqlDatabases@2023-11-15' = {
    name: cosmosDbDatabaseName
    properties: {
      resource: {
        id: cosmosDbDatabaseName
      }
    }

    resource cosmosDbUsersContainer 'containers@2023-11-15' = {
      name: cosmosDbContainerName
      properties: {
        resource: {
          id: cosmosDbContainerName
          partitionKey: {
            paths: [ '/partitionkey' ]
            kind: 'Hash'
          }
        }
      }
    }
  }
}

module pdnsStorageAccModule '../../modules/network/private-dns-zone/main.bicep' = {
  name: '${appName}-storage-acc-pds-deployment'
  params: {
    name: 'privatelink.file.core.windows.net'
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnetModule.outputs.resourceId
      }
    ]
  }
}

// resource workspaceResource 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
//   name: workspaceName
//   location: location
// }

module storageModule '../../modules/storage/storage-account/main.bicep' = {
  name: '${appName}-storage-deployment'
  params: {
    name: storageName
    location: location
    supportsHttpsTrafficOnly: false
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    publicNetworkAccess: 'Enabled'
    fileServices: {
      name: '${storageName}-fs'
    }
    privateEndpoints: [
      {
        name: '${appName}-pe-storage-acc'
        service: 'file'
        subnetResourceId: az.resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', vnetModule.outputs.name, defaultSubnetName)
        privateDnsZoneResourceIds: [
          pdnsStorageAccModule.outputs.resourceId
        ]
      }
    ]
    // roleAssignments: [
    //   {
    //     principalId: idPaperMcModule.outputs.principalId
    //     // Storage Account Contributor
    //     roleDefinitionIdOrName: '/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab'
    //   }
    // ]
  }
}

module workspaceModule '../../modules/operational-insights/workspace/main.bicep' = {
  name: '${workspaceName}-deployment'
  params: {
    name: workspaceName
    location: location
  }
}

// module idPaperMcModule '../../modules/managed-identity/user-assigned-identity/main.bicep' = {
//   name: '${appName}-id-papermc-deployment'
//   params: {
//     name: '${appName}-id-papermc'
//     location: location
//   }
// }

// module vmHubModule '../../modules/compute/virtual-machine/main.bicep' = {
//   name: '${appName}-vm-deployment'
//   params: {
//     name: '${appName}-vm'
//     location: location
//     disablePasswordAuthentication: false
//     adminPassword: 'AppelPeerBanaan123'
//     adminUsername: 'localAdminUser'
//     encryptionAtHost: false
//     imageReference: {
//       offer: '0001-com-ubuntu-server-jammy'
//       publisher: 'Canonical'
//       sku: '22_04-lts-gen2'
//       version: 'latest'
//     }
//     nicConfigurations: [
//       {
//         ipConfigurations: [
//           {
//             name: '${appName}-hub-vm-ip-config'
//             privateIPAddress: '10.0.0.4'
//             privateIPAllocationMethod: 'Static'
//             pipConfiguration: {
//               publicIpNameSuffix: '-pip-01'
//             }
//             subnetResourceId: defaultSubnetModule.outputs.resourceId
//           }
//         ]
//         nicSuffix: '-nic-01'
//       }
//     ]
//     osDisk: {
//       diskSizeGB: '128'
//       managedDisk: {
//         storageAccountType: 'Premium_LRS'
//       }
//     }
//     osType: 'Linux'
//     vmSize: 'Standard_DS2_v2'

//   }
// }
