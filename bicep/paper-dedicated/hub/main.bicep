param appName string
param suffix string
param storageName string
param paperShareName string
param cappEnvName string
@secure()
param googleClientId string
@secure()
param googleClientSecret string

var cappStorageDefName = 'st-def-${appName}-${suffix}'
var cappEnvSubnetName = 'sn-env-${appName}-${suffix}'
var vnetName = 'vnet-${appName}-${suffix}'
var workspaceName = 'law-${appName}-${suffix}'
var location = resourceGroup().location

module networkModule 'infra.bicep' = {
  name: 'network-${appName}-${suffix}-deployment'
  params: {
    suffix: suffix
    appName: appName
    location: location
    cappEnvSubnetName: cappEnvSubnetName
    storageName: storageName
    vnetName: vnetName
    workspaceName: workspaceName
    cosmosDbAccountName: 'cosmos-${appName}-${suffix}'
    cosmosDbDatabaseName: 'cosmos-db-${appName}-${suffix}'
    cosmosDbContainerName: 'cosmos-users-${appName}-${suffix}'
  }
}

module appModule 'app.bicep' = {
  name: 'app-${appName}-${suffix}-deployment'
  params: {
    appName: appName
    location: location
    cappEnvName: cappEnvName
    cappEnvSubnetName: cappEnvSubnetName
    storageName: storageName
    vnetName: vnetName
    workspaceName: workspaceName
    googleClientId: googleClientId
    googleClientSecret: googleClientSecret
  }
  dependsOn: [ networkModule ]
}
