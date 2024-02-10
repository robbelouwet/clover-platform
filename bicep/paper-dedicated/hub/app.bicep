// param workspaceName string
param cappEnvName string
param appName string
// param suffix string
// param vnetName string
// param cappEnvSubnetName string
param storageName string
// param cappStorageDefName string
// param paperShareName string

var location = resourceGroup().location

// resource workspaceResource 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
//   name: workspaceName
// }

// resource idPaperServer 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
//   name: '${appName}-id-paper-${suffix}'
// }

resource cappEnvironment 'Microsoft.App/managedEnvironments@2022-10-01' = {
  name: cappEnvName
  // location: location
  // sku: { name: 'Consumption' }
  // properties: {
  //   appLogsConfiguration: {
  //     destination: 'log-analytics'
  //     logAnalyticsConfiguration: {
  //       customerId: workspaceResource.properties.customerId
  //       sharedKey: workspaceResource.listKeys().primarySharedKey
  //     }
  //   }
  //   vnetConfiguration: {
  //     internal: false
  //     infrastructureSubnetId: az.resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, cappEnvSubnetName)
  //     dockerBridgeCidr: '10.2.0.1/16'
  //     platformReservedCidr: '10.1.0.0/16'
  //     platformReservedDnsIP: '10.1.0.2'
  //   }
  // }
  // dependsOn: [ workspaceResource ]
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageName
}

resource paperBackend 'Microsoft.App/containerapps@2023-05-02-preview' = {
  name: '${appName}-server'
  location: location
  // identity: {
  //   type: 'UserAssigned'
  //   userAssignedIdentities: {
  //     '${idPaperServer.id}': {}
  //   }
  // }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: cappEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 5000
        transport: 'Http'
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
          image: 'robbelouwet/paper-backend:latest'
          name: 'backend-container'
          env: [
            {
              name: 'ST_ACC_CONN_STRING'
              value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
            }
            {
              name: 'ST_ACC_RG'
              value: resourceGroup().name
            }
            {
              name: 'CAPP_ENV_NAME'
              value: cappEnvironment.name
            }
            {
              name: 'ST_ACC_NAME'
              value: storageName
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          probes: []
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
      }
    }
  }
  dependsOn: [ cappEnvironment ]
}

var roleDefinitionIds = [
  subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
]
resource roleAssignmentModule 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for role in roleDefinitionIds: {
  name: guid(resourceGroup().name, last(split(role, '/')))
  scope: resourceGroup()
  properties: {
    principalId: paperBackend.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: role
  }
}]
