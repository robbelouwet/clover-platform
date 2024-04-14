using 'server.bicep'

param location = 'westeurope'
var env = 'dev'

param storageName = 'st${location}${env}c01' // 'c' is for consumption
param servername = 'robbe'
param cappEnvName = 'paper-capp-env-dev-02' //'env-cluster-${location}-${env}-01'

param memoryMB = 4096
param vcpu = '2'
param consolePort = 5432
param velocitySecret = 'zekKr2hm'
