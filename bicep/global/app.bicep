param location string
param workspaceName string
param cappEnvName string
param appName string
param vnetName string
param cappEnvSubnetName string
param storageName string
param cosmosDbAccountName string
param cosmosDbDatabaseName string
param cosmosDbUsersContainerName string
param cosmosDbServersContainerName string
param dnsZone string
param suffix string
@secure()
param velocitySecret string
@secure()
param googleClientId string
@secure()
param googleClientSecret string

resource workspaceResource 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageName
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
      name: cosmosDbUsersContainerName
      properties: {
        resource: {
          id: cosmosDbUsersContainerName
          partitionKey: {
            paths: ['/id']
            kind: 'Hash'
          }
        }
      }
    }

    resource cosmosDbServersContainer 'containers@2023-11-15' = {
      name: cosmosDbServersContainerName
      properties: {
        resource: {
          id: cosmosDbServersContainerName
          partitionKey: {
            paths: ['/id']
            kind: 'Hash'
          }
        }
      }
    }
  }
}

resource paperBackend 'Microsoft.App/containerapps@2023-05-02-preview' = {
  name: '${appName}-backend'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: cappEnvironment.id
    configuration: {
      secrets: [
        {
          name: 'google-client-secret'
          value: googleClientSecret
        }
      ]
      ingress: {
        corsPolicy: {
          allowCredentials: true
          allowedOrigins: [
            '*'
          ]
        }
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
              name: 'D_ST_ACC_NAME'
              value: ??
            }
            {
              name: 'D_ST_ACC_CONN_STRING'
              value: ???
            }
            {
              name: 'C_ST_ACC_NAME'
              value: ???
            }
            {
              name: 'C_ST_ACC_CONN_STRING'
              value: ???
            }
            {
              name: 'RG'
              value: resourceGroup().name
            }
            {
              name: 'DNS_ZONE'
              value: dnsZone
            }
            {
              name: 'CAPP_ENVIRONMENT_NAME'
              value: cappEnvironment.name
            }
            {
              name: 'COSMOS_ENDPOINT'
              value: 'https://${cosmosdb.name}.documents.azure.com:443/'
            }
            {
              name: 'COSMOS_KEY'
              value: cosmosdb.listKeys().primaryMasterKey
            }
            {
              name: 'COSMOS_DB_NAME'
              value: cosmosDbDatabaseName
            }
            {
              name: 'COSMOS_USERS_CONTAINER_NAME'
              value: cosmosDbUsersContainerName
            }
            {
              name: 'COSMOS_SERVERS_CONTAINER_NAME'
              value: cosmosDbServersContainerName
            }
            {
              name: 'VELOCITY_SECRET'
              value: velocitySecret
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
  resource auth 'authConfigs@2023-05-01' = {
    name: 'current'
    properties: {
      globalValidation: {
        unauthenticatedClientAction: 'Return401'
      }
      platform: {
        enabled: true
      }
      identityProviders: {
        google: {
          enabled: true
          registration: {
            clientId: googleClientId
            clientSecretSettingName: 'google-client-secret'
          }
        }
      }
    }
  }
}

var roleDefinitionIds = [
  subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
]
resource roleAssignmentModule 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in roleDefinitionIds: {
    name: guid(resourceGroup().name, last(split(role, '/')))
    scope: resourceGroup()
    properties: {
      principalId: paperBackend.identity.principalId
      principalType: 'ServicePrincipal'
      roleDefinitionId: role
    }
  }
]
