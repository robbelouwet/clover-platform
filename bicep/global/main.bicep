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

var defaultSubnet = '10.0.0.0/24'
var cappEnvSubnet = '10.0.2.0/23'

var defaultSubnetName = 'sn-default-${appName}-${suffix}'
var cappEnvSubnetName = 'sn-env-${appName}-${suffix}'
var vnetName = 'vnet-${appName}-${suffix}'
var workspaceName = 'law-${appName}-${suffix}'
var location = resourceGroup().location

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
