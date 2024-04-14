param servername string
param storageName string
param cappEnvName string
param location string = resourceGroup().location
@allowed([1024, 2048, 3072, 4096])
param memoryMB int
@allowed(['0.5', '1', '1.5', '2'])
param vcpu string
param consolePort int
@secure()
param velocitySecret string

var fileShareName = 'fs-${servername}'
var stDefName = 'st-def-${servername}'

resource env 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
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
    fileServicesName: 'default'
    accessTier: 'Premium'
    enabledProtocols: 'NFS'
    shareQuota: 100
    rootSquash: 'NoRootSquash'
  }
}

resource storageDef 'Microsoft.App/managedEnvironments/storages@2023-11-02-preview' = {
  name: stDefName
  parent: env
  properties: {
    nfsAzureFile: {
      server: '${storageAccResource.name}.privatelink.file.core.windows.net'
      accessMode: 'ReadWrite'
      shareName: '/${storageAccResource.name}/${fileShareName}'
    }
  }
}

resource paperCAPP 'Microsoft.App/containerapps@2023-05-02-preview' = {
  name: servername
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8765
        exposedPort: consolePort
        transport: 'Tcp'
        additionalPortMappings: [
          {
            targetPort: 25565
            external: false
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
          image: 'robbelouwet/paper-consumption:latest'
          name: 'server-container'
          env: [
            {
              name: 'VELOCITY_SECRET'
              value: velocitySecret
            }
          ]
          resources: {
            cpu: json(vcpu)
            memory: '${memoryMB / 1024}Gi'
          }
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
          storageType: 'NfsAzureFile'
          storageName: storageDef.name
        }
      ]
    }
  }
  dependsOn: [fileShareModule]
}

output defaultHost string = paperCAPP.properties.configuration.ingress.fqdn
output fileShareId string = fileShareModule.outputs.resourceId
output containerAppId string = paperCAPP.id
output storageDefinitionId string = storageDef.id
