param workspaceName string
param clusterName string
param suffix string
param vnetName string
param cappEnvSubnetName string
param dockerBridgeCidr string
param platformReservedCidr string
param platformReservedDnsIP string
param storageName string
param cappEnvName string

@secure()
param velocitySecret string

var location = resourceGroup().location
var privateLinkZone = 'privatelink.file.core.windows.net'

resource workspaceResource 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

// module pdnsZone '../../modules/network/private-dns-zone/main.bicep' = {
//   name: '${privateLinkZone}-deployment'
//   params: {
//     name: privateLinkZone
//     location: 'global'
//     virtualNetworkLinks: [
//       {
//         virtualNetworkResourceId: az.resourceId('Microsoft.Network/virtualNetworks', vnetName)
//       }
//     ]
//   }
// }

// module stacc '../../modules/storage/storage-account/main.bicep' = {
//   name: '${storageName}-deployment'
//   params: {
//     name: storageName
//     location: location
//     kind: 'FileStorage'
//     skuName: 'Premium_LRS'
//     supportsHttpsTrafficOnly: false
//     privateEndpoints: [
//       {
//         service: 'file'
//         privateDnsZoneGroupName: 'privatelink.file.core.windows.net'
//         privateDnsZoneResourceIds: [
//           pdnsZone.outputs.resourceId
//         ]
//         subnetResourceId: az.resourceId(
//           'Microsoft.Network/virtualNetworks/subnets',
//           vnetName,
//           'sn-default-paper-dev-02' //'sn-default-${clusterName}-${suffix}'
//         )
//       }
//     ]
//   }
// }

resource cappEnvironment 'Microsoft.App/managedEnvironments@2022-10-01' existing = {
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
  //     dockerBridgeCidr: dockerBridgeCidr
  //     platformReservedCidr: platformReservedCidr
  //     platformReservedDnsIP: platformReservedDnsIP
  //   }
  // }
  // dependsOn: [workspaceResource]
}

resource velocityCAPP 'Microsoft.App/containerapps@2023-05-02-preview' = {
  name: 'velocity-${suffix}'
  location: location
  properties: {
    managedEnvironmentId: cappEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 25565
        exposedPort: 25565
        transport: 'Tcp'
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
          image: 'robbelouwet/velocity-consumption'
          name: 'velocity-container'
          env: [
            {
              name: 'VELOCITY_SECRET'
              value: velocitySecret
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10 // Should set maximum to account for DDOS attacks
      }
    }
  }
}
