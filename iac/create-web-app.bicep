// Create web app

param applicationName string
param postFixName string
@allowed([
  'dev'
  'test'
  'prod'
])
param deploymentEnvironment string
param location string = resourceGroup().location
param keyVaultUri string
param siteAlwaysOn bool = false

@allowed([
  'single'
  'main'
  'replica'
])
param websiteRegistrar string

var identityAppName = 'id-${applicationName}-${deploymentEnvironment}-${location}'
var appServicePlanName = toLower('asp-${applicationName}-${deploymentEnvironment}-${location}${postFixName}')
var appName = '${applicationName}-${deploymentEnvironment}-${location}${postFixName}'
var webSiteName = toLower('wapp-${appName}')

// -----------------------------------------------------------------------------------------------
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: identityAppName
}

// -----------------------------------------------------------------------------------------------
resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' existing = {
  name: appServicePlanName
}

resource appServiceMain 'Microsoft.Web/sites@2021-03-01' = {
  name: webSiteName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  tags: {
    displayName: 'Website'
    ProjectName: appName
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    keyVaultReferenceIdentity: identity.id
    siteConfig: {
      minTlsVersion: '1.2'
      netFrameworkVersion: 'v4.8'
      alwaysOn: siteAlwaysOn
      appSettings:[
        {
          name: 'apikeycreatecustomerlogin'
          value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/apikeycreatecustomerlogin/)'
        }
        {
          name: 'apikeyinternalapis'
          value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/apikeyinternalapis/)'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/APPINSIGHTSINSTRUMENTATIONKEY/)'
        }
        {
          name: 'APPINSIGHTS_PROFILERFEATURE_VERSION'
          value: '1.0.0'
        }
        {
          name: 'APPINSIGHTS_SNAPSHOTFEATURE_VERSION'
          value: '1.0.0'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/APPLICATIONINSIGHTSCONNECTIONSTRING/)'
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'AZURE_KEYVAULT_URI'
          value: keyVaultUri
        }
        {
          name: 'AZURE_STORAGE_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/AZURESTORAGECONNECTIONSTRING/)'
        }
        {
          name: 'AzureBlobFileSystem.ConnectionString:forms'
          value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/AzureBlobFileSystemConnectionStringforms/)'
        }
        {
          name: 'AzureBlobFileSystem.ConnectionString:media'
          value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/AzureBlobFileSystemConnectionStringmedia/)'
        }
        {
          name: 'Environment'
          value: deploymentEnvironment
        }
        {
          name: 'Catalog:BlobConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/CatalogBlobConnectionString/)'
        }
        {
          name: 'REDIS_ACCESS_KEY'
          value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/REDISACCESSKEY/)'
        }
        {
          name: 'WEBSITE_REGISTRAR'
          value: websiteRegistrar
        }
      ]
    connectionStrings: [
        {
          name: 'redis'
          connectionString: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/ConnectionStringRedis/)'
          type: 'Custom'
        }
        {
          name: 'commerce'
          connectionString: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/CommerceConnectionString/)'
          type: 'SQLServer'
        }
        {
          name: 'cms'
          connectionString: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/CmsConnectionString/)'
          type: 'SQLServer'
        }
      ]
    }
  }
}
