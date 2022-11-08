// Create:
// - server
// - pool
// - database

param adGroupsChangeThisId string // param should be removed
param sqlDbLogInChangeThis string // param should be removed

param applicationName string
@allowed([
  'dev'
  'test'
  'prod'
])
param deploymentEnvironment string
param location string = resourceGroup().location
param skuName string = 'StandardPool'
param tier string = 'Standard'
param poolPerformanceMax int = 50
param poolSize int = 53687091200
param zoneRedundant bool = false
param elasticPoolTags object = {}

var serverName = 'sql-${applicationName}-${deploymentEnvironment}'
var elasticPoolName = 'sqlpool-${applicationName}-${deploymentEnvironment}'
var sqlDbName = 'sqldb-${applicationName}-${deploymentEnvironment}'
var sqlDbNameCommerce = 'sqldb-${applicationName}-${deploymentEnvironment}-commerce'
#disable-next-line no-unused-vars
var adGroups = {
  // changethis: for the example all groups share the same group ID. It will most likely be
  //              three different values
  dev:  adGroupsChangeThisId  // changethis - hardcode, or have another way to insert id
  test: adGroupsChangeThisId  // changethis - hardcode, or have another way to insert id
  prod: adGroupsChangeThisId  // changethis - hardcode, or have another way to insert id
}

// Create resources -----------------------------------------------------------------------------------------------
resource sql 'Microsoft.Sql/servers@2021-05-01-preview' = {
  name: serverName
  location: location
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
      login: sqlDbLogInChangeThis // changethis 'sql-admins-${deploymentEnvironment}'
      sid: adGroups[deploymentEnvironment]
      tenantId: subscription().tenantId
      azureADOnlyAuthentication: true
    }
  }
}

resource sqlElasticPool 'Microsoft.Sql/servers/elasticpools@2021-02-01-preview' = {
  name: '${sql.name}/${elasticPoolName}'
  tags: elasticPoolTags
  location: location
  sku: {
    name: skuName
    tier: tier
    capacity: poolPerformanceMax
  }
  properties: {
    maxSizeBytes: poolSize
    zoneRedundant: zoneRedundant
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  name: toLower('${sql.name}/${sqlDbName}')
  location: location
  properties:{
    elasticPoolId: sqlElasticPool.id
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: zoneRedundant
  }
}

resource sqlDBCommerce 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  name: toLower('${sql.name}/${sqlDbNameCommerce}')
  location: location
  properties:{
    elasticPoolId: sqlElasticPool.id
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: zoneRedundant
  }
}

// Outputs -----------------------------------------------------------------------------------------------
#disable-next-line no-hardcoded-env-urls
output connectionStringCmsCore string = 'Server=tcp:${serverName}.database.windows.net;Authentication=Active Directory Interactive; Database=${sqlDbName};'
#disable-next-line no-hardcoded-env-urls
output connectionStringCommerceCore string = 'Server=tcp:${serverName}.database.windows.net;Authentication=Active Directory Interactive; Database=${sqlDbName};'
#disable-next-line no-hardcoded-env-urls
output connectionStringCmsFramework string = 'Server=tcp:${serverName}.database.windows.net,1433;Initial Catalog=${sqlDbName};user id=${sqlDbName}-user;password=change-this'
#disable-next-line no-hardcoded-env-urls
output connectionStringCommerceFramework string = 'Server=tcp:${serverName}.database.windows.net,1433;Initial Catalog=${sqlDbNameCommerce};user id=${sqlDbName}-user;password=change-this'
