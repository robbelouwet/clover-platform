var staccname = 'stwesteuropedevc01'
var appName = 'testapp'
var fileShareName = 'test-share'
var location = resourceGroup().location
var privateLinkZone = 'privatelink.file.core.windows.net'

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: 'vnet-paper-dev-02'
}

resource env 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: 'paper-capp-env-dev-02'
}

resource storageDef 'Microsoft.App/managedEnvironments/storages@2023-11-02-preview' = {
  name: 'st-def-${appName}'
  parent: env
  properties: {
    nfsAzureFile: {
      server: '${staccname}.${privateLinkZone}'
      accessMode: 'ReadWrite'
      shareName: '/${stacc.outputs.name}/${fileShareName}'
    }
  }
}

module pdnsZone '../modules/network/private-dns-zone/main.bicep' = {
  name: '${privateLinkZone}-deployment'
  params: {
    name: privateLinkZone
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnet.id
      }
    ]
  }
}

module stacc '../modules/storage/storage-account/main.bicep' = {
  name: '${staccname}-deployment'
  params: {
    name: staccname
    location: location
    kind: 'FileStorage'
    skuName: 'Premium_LRS'
    supportsHttpsTrafficOnly: false
    privateEndpoints: [
      {
        service: 'file'
        privateDnsZoneGroupName: privateLinkZone
        privateDnsZoneResourceIds: [
          pdnsZone.outputs.resourceId
        ]
        subnetResourceId: az.resourceId(
          'Microsoft.Network/virtualNetworks/subnets',
          vnet.name,
          'sn-default-paper-dev-02'
        )
      }
    ]
    fileServices: {
      shares: [
        {
          accessTier: 'Premium'
          name: fileShareName
          enabledProtocols: 'NFS'
          rootSquash: 'NoRootSquash'
          shareQuota: 100
        }
      ]
    }
  }
  dependsOn: [vnet]
}

resource paperCAPP 'Microsoft.App/containerApps@2023-11-02-preview' = {
  name: '${appName}-server'
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8765
        exposedPort: 5433
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
              value: 'zekKr2hm'
            }
          ]
          resources: {
            cpu: json('1.5')
            memory: '3Gi'
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
        minReplicas: 1
        maxReplicas: 1
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
  dependsOn: [
    stacc
  ]
}
