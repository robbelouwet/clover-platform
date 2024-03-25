using 'server.bicep'

param appName = 'paper'
param storageName = 'paperstoragedev02'
param servername = 'robbe2'
param cappEnvName = 'paper-capp-env-dev-02'
param exposedServerPort = 30000
param dnsZone = 'clover-host.com'

param memoryMB = 4096
param vcpu = '2'
param velocitySecret = 'zekKr2hm'
