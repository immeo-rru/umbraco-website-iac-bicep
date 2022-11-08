// Create Function-app

param applicationName string
param postFixName string

@description('The name of the deploymentEnvironment being deployed to.')
@allowed([
  'dev'
  'test'
  'prod'
])
param deploymentEnvironment string
param location string = resourceGroup().location
param keyVaultUri string

@description('Connection string for the storage account used by the function app.')
param storageAccountConnectionString string

@description('The instrumentation key of the application insights to log to.')
param appInsightsInstrumentationKey string


var appServicePlanName = toLower('asp-${applicationName}-${deploymentEnvironment}-${location}${postFixName}')
var identityAppName = 'id-${applicationName}-${deploymentEnvironment}-${location}'
var functionAppName = 'func-${applicationName}-${deploymentEnvironment}-${location}'

// -----------------------------------------------------------------------------------------------
resource appServicePlan 'Microsoft.Web/serverFarms@2020-06-01' existing = {
  name: appServicePlanName
}
// -----------------------------------------------------------------------------------------------
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: identityAppName
}
// -----------------------------------------------------------------------------------------------

resource functionApp 'Microsoft.Web/sites@2021-01-15' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${functionAppName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${functionAppName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
    ]
    serverFarmId: appServicePlan.id
    reserved: false
    isXenon: false
    hyperV: false
    keyVaultReferenceIdentity: identity.id
    siteConfig: {
      appSettings: [
        // Default Azure settings
        // change-this: some settings, add your own here
        {
          name: 'AzureWebJobsStorage'
          value: storageAccountConnectionString
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageAccountConnectionString
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsightsInstrumentationKey}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4' // 4 -> .net core 6
        }
        {
          // WEBSITE_RUN_FROM_PACKAGE is set automatically by the AzureFunctionApp Azue Pipelines task.
          // We need to set it to the same value, so it is not rolled back when we deploy this.
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: identity.properties.clientId
        }
        // Custom settings for our own code
        {
          name: 'ExternalStorage:BlobConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/PimBlobConnectionString/)'
        }
        {
          name: 'ExternalStorage:BlobDataContainerName'
          value: 'catalog-data'
        }
        {
          name: 'ExternalStorage:BlobImagesContainerName'
          value: 'catalog-images'
        }
        {
          name: 'CommerceConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/CommerceConnectionString/)'
        }
      ]
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    hostNamesDisabled: false
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
  }
}

resource functionAppConfig 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: functionApp
  name: 'web'
  properties: {
    //numberOfWorkers: -1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v6.0'
    phpVersion: '5.6'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: functionAppName
    // scmType is set automatically by the AzureFunctionApp Azue Pipelines task.
    // We need to set it to the same value, so it is not rolled back when we deploy this.
    scmType: 'VSTSRM'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    // Timer triggers will stop after a while unless alwaysOn is true.
    alwaysOn: true
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    cors: {
      allowedOrigins: [
        'https://functions.azure.com'
        'https://functions-staging.azure.com'
        'https://functions-next.azure.com'
      ]
      supportCredentials: false
    }
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: true
    minTlsVersion: '1.2'
    ftpsState: 'Disabled'
    preWarmedInstanceCount: 0
  }
}

output resourceId string = functionApp.id
