// Create managed identity

param applicationName string

@allowed([
  'dev'
  'test'
  'prod'
])
param deploymentEnvironment string
param location string = resourceGroup().location

var appName = 'id-${applicationName}-${deploymentEnvironment}-${location}'

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: appName
  location: location
}

output principalId string = identity.properties.principalId
output clientId string = identity.properties.clientId
output tenantId string = identity.properties.tenantId
