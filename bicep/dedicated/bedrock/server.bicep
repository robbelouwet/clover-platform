param servername string
param appName string
param storageName string
param memoryMB int
param vcpu string
param location string = resourceGroup().location
param dnsZone string

var fileShareName = 'fs-${appName}-${servername}'
var aciName = 'aci-${appName}-${servername}'
var volumeName = 'volume-${appName}-${servername}'

var gameplayPort = 25565
var consolePort = 8765

resource storageAccResource 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageName
}

module fileShareModule '../../modules/storage/storage-account/file-service/share/main.bicep' = {
  name: '${fileShareName}-deployment'
  params: {
    name: fileShareName
    storageAccountName: storageAccResource.name
    fileServicesName: 'default' //'${storageAccResource.name}-fs'
    accessTier: 'Hot'
    enabledProtocols: 'SMB'
  }
}

resource bedrockContainerInstance 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: aciName
  location: location
  properties: {
    ipAddress: {
      autoGeneratedDomainNameLabelScope: 'Noreuse'
      dnsNameLabel: 'dns-${servername}'
      ports: [
        {
          port: gameplayPort
          protocol: 'UDP'
        }
        {
          port: consolePort
          protocol: 'TCP'
        }
      ]
      type: 'Public'
    }
    containers: [
      {
        name: 'server-container'
        properties: {
          image: 'robbelouwet/bedrock-dedicated'
          ports: [
            {
              port: gameplayPort
              protocol: 'UDP'
            }
            {
              port: consolePort
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: json(vcpu)
              memoryInGB: memoryMB / 1024
            }
          }
          volumeMounts: [
            {
              mountPath: '/data'
              name: volumeName
              readOnly: false
            }
          ]
        }
      }
    ]
    volumes: [
      {
        azureFile: {
          readOnly: false
          shareName: fileShareModule.outputs.name
          storageAccountKey: storageAccResource.listKeys().keys[0].value
          storageAccountName: storageAccResource.name
        }
        name: volumeName
      }
    ]
    osType: 'Linux'
  }
}

resource zone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: dnsZone
}

resource record 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  parent: zone
  name: servername
  properties: {
    TTL: 3600
    CNAMERecord: {
      cname: bedrockContainerInstance.properties.ipAddress.fqdn
    }
  }
}

output host string = '${servername}.${dnsZone}'
output shareName string = fileShareName
output stAccName string = storageName
output aciName string = bedrockContainerInstance.name
output location string = location
