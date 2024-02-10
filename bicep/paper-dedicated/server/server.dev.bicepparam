using 'server.bicep'

param appName = 'paper'
param storageName = 'paperstoragedev01'
param servername = 'robbe3'
param cappEnvName = 'paper-capp-env-dev-01'
param exposedServerPort = 30000

param memoryMB = 4096
param vcpu = '2'
