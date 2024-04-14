using 'main.bicep'

var env = 'dev'

param appName = 'hub'
var escapedAppName = 'hub'

param suffix = '${env}-01'
var escapedSuffix = '${env}01'

param storageName = '${escapedAppName}storage${escapedSuffix}'
param cappEnvName = '${appName}-capp-env-${suffix}'
param googleClientId = '482838418988-denpsi6uici9e9np5fp9p6r0sj3qeatn.apps.googleusercontent.com'
param googleClientSecret = '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'
param velocitySecret = 'zekKr2hm'
param dnsZone = 'clover-host.com'
