param servername string
param appName string
param storageName string
param cappEnvName string
param exposedServerPort int = 25565

@allowed([ 1024, 2048, 3072, 4096 ])
param memoryMB int
@allowed([ '0.5', '1', '1.5', '2' ])
param vcpu string

var location = resourceGroup().location
var fileShareName = 'fs-${appName}-${servername}'

resource cappEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: cappEnvName
}

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

resource storageDef 'Microsoft.App/managedEnvironments/storages@2023-05-01' = {
  name: 'st-def-${appName}-${servername}'
  parent: cappEnvironment
  properties: {
    azureFile: {
      accessMode: 'ReadWrite'
      accountKey: storageAccResource.listKeys().keys[0].value
      accountName: storageName
      shareName: fileShareModule.outputs.name
    }
  }
}

resource paperCAPP 'Microsoft.App/containerapps@2023-05-02-preview' = {
  name: 'capp-${appName}-${servername}-server'
  location: location
  // identity: {
  //   type: 'UserAssigned'
  //   userAssignedIdentities: {
  //     '${idPaperServer.id}': {}
  //   }
  // }
  properties: {
    managedEnvironmentId: cappEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 25565
        exposedPort: exposedServerPort
        transport: 'Tcp'
        additionalPortMappings: [
          // Port mapping for the STDIO wrapper
          {
            exposedPort: exposedServerPort + 1
            targetPort: 8765
            external: true
          }
        ]
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
    }
    template: {
      containers: [
        {
          image: 'robbelouwet/paper-dedicated:latest'
          name: 'server-container'
          env: [
            {
              name: 'JVM_ARGS'
              value: '-Xms${(memoryMB / 100) * 5}M -Xmx${(memoryMB / 100) * 95}M' // 5% - 95%% of container memory reserved for server process
            }
          ]
          resources: {
            cpu: json(vcpu)
            memory: '${memoryMB / 1024}Gi'
          }
          probes: []
          volumeMounts: [
            {
              volumeName: fileShareName
              mountPath: '/data'
            }
          ]
        }
      ]
      scale: {

        minReplicas: 0
        maxReplicas: 1
        rules: [
          {
            name: 'tcp-scaler'
            tcp: {
              metadata: {
                concurrentRequests: '1000'
              }
            }
          }
        ]
      }
      volumes: [
        {
          name: fileShareName
          storageType: 'AzureFile'
          storageName: storageDef.name
        }
      ]
    }
  }
}

output host string = '${paperCAPP.properties.configuration.ingress.fqdn}:${paperCAPP.properties.configuration.ingress.exposedPort}'
