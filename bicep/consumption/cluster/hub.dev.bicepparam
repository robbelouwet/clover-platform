using 'main.bicep'

param clusterName = 'cluster'
param location = 'westeurope'
var env = 'dev'

param suffix = '${location}-${env}c-01' // 'c' is for consumption
var escapedSuffix = replace(suffix, '-', '')

param storageName = 'st${escapedSuffix}'
param cappEnvName = 'paper-capp-env-dev-02' //'env-${clusterName}-${suffix}'
param velocitySecret = 'zekKr2hm'
