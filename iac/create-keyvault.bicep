// Create key vault

param applicationName string
@allowed([
  'dev'
  'test'
  'prod'
])
param deploymentEnvironment string
param location string = resourceGroup().location

@description('Access policies for the key vault. Format: {objectId: string, readOnly: boolean}')
param accessPolicies array = []

@description('The Client ID of a managed identity that should be used to call ARM listKeys() and update secrets in this key vault. Leave blank to disable automatic secret updates.')
param keyUpdateClientId string = ''

@description('Keyvault default access policies needs to know which AD group. Change-this: the same param is used for all environments for simplicity reasons.')
param defaultAccessPolicyAdminGroupObjectId string

var enabledForTemplateDeployment = false
var keyVaultName = 'kv-${applicationName}-${deploymentEnvironment}-2'

var defaultAccessPolicies = {
  dev: [ 
    {
      objectId: defaultAccessPolicyAdminGroupObjectId // ID for AD Group (GUID)
      readOnly: false
    }
  ]
  test: [
    {
      objectId: defaultAccessPolicyAdminGroupObjectId // ID for AD Group (GUID)
      readOnly: false
    }
  ]
  prod: [
    {
      objectId: defaultAccessPolicyAdminGroupObjectId // ID for AD Group (GUID)
      readOnly: false
    }
  ]
}

// -----------------------------------------------------------------------------------------------

var allAccessPolicies = concat(accessPolicies, defaultAccessPolicies[deploymentEnvironment])

var fullPermissions = {
  certificates: [
    'get'
    'list'
    'update'
    'create'
    'import'
    'delete'
    'recover'
    'Backup'
    'Restore'
    'managecontacts'
    'manageissuers'
    'getissuers'
    'listissuers'
    'setissuers'
    'deleteissuers'
  ]
  keys: [
    'get'
    'list'
    'update'
    'create'
    'import'
    'delete'
    'recover'
    'backup'
    'restore'
  ]
  secrets: [
    'get'
    'list'
    'set'
    'delete'
    'recover'
    'backup'
    'restore'
  ]
}

var readPermissions = {
  certificates: [
    'get'
    'list'
    'getissuers'
    'listissuers'
  ]
  keys: [
    'get'
    'list'
  ]
  secrets: [
    'get'
    'list'
  ]
}
// -----------------------------------------------------------------------------------------------

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies: [for accessPolicy in allAccessPolicies: {
      objectId: accessPolicy.objectId
      permissions: accessPolicy.readOnly ? readPermissions : fullPermissions
      tenantId: subscription().tenantId
    }]
    enableSoftDelete: true
    enablePurgeProtection: true
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: enabledForTemplateDeployment
    sku: {
      family:'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
  }
  tags: {
    KeyUpdateClientId: keyUpdateClientId
  }
}

output vaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVaultName
