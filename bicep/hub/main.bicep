param appName string
param suffix string
param storageName string
param cappEnvName string
param dnsZone string
@secure()
param velocitySecret string
@secure()
param googleClientId string
@secure()
param googleClientSecret string

var defaultSubnetName = 'sn-default-${appName}-${suffix}'
var defaultSubnet = '10.0.0.0/24'
var cappEnvSubnet = '10.0.2.0/23'

var cappEnvSubnetName = 'sn-env-${appName}-${suffix}'
var vnetName = 'vnet-${appName}-${suffix}'
var workspaceName = 'law-${appName}-${suffix}'
var location = resourceGroup().location

module workspaceModule '../modules/operational-insights/workspace/main.bicep' = {
  name: '${workspaceName}-deployment'
  params: {
    name: workspaceName
    location: location
  }
}

module vnetModule '../modules/network/virtual-network/main.bicep' = {
  name: '${vnetName}-deployment'
  params: {
    name: vnetName
    location: location
    addressPrefixes: ['10.0.0.0/16']
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

module pdnsStorageAccModule '../modules/network/private-dns-zone/main.bicep' = {
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

module storageModule '../modules/storage/storage-account/main.bicep' = {
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
        subnetResourceId: az.resourceId(
          subscription().subscriptionId,
          resourceGroup().name,
          'Microsoft.Network/virtualNetworks/subnets',
          vnetModule.outputs.name,
          defaultSubnetName
        )
        privateDnsZoneResourceIds: [
          pdnsStorageAccModule.outputs.resourceId
        ]
      }
    ]
  }
}

module appModule './app.bicep' = {
  name: 'app-${appName}-${suffix}-deployment'
  params: {
    appName: appName
    suffix: suffix
    dnsZone: dnsZone
    location: location
    cappEnvName: cappEnvName
    cappEnvSubnetName: cappEnvSubnetName
    storageName: storageName
    vnetName: vnetName
    workspaceName: workspaceName
    googleClientId: googleClientId
    googleClientSecret: googleClientSecret
    cosmosDbAccountName: 'cosmos-${appName}-${suffix}'
    cosmosDbDatabaseName: 'cosmos-db-${appName}-${suffix}'
    cosmosDbUsersContainerName: 'cosmos-users-${appName}-${suffix}'
    cosmosDbServersContainerName: 'cosmos-servers-${appName}-${suffix}'
    velocitySecret: velocitySecret
  }
  dependsOn: [workspaceModule, storageModule]
}
