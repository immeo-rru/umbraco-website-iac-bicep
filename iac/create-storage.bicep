// Create storage account and blob container
param applicationName string
@allowed([
  'dev'
  'test'
  'prod'
])
param deploymentEnvironment string
param location string = resourceGroup().location

var stName = 'st${applicationName}${deploymentEnvironment}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: stName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name: '${storageAccount.name}/default'
  properties: {
    changeFeed: {
      enabled: true
    }
    restorePolicy: {
      enabled: true
      days: 14
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 15
    }
    isVersioningEnabled: true
  }
}

#disable-next-line outputs-should-not-contain-secrets
output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, '2019-06-01').keys[0].value}'
output storageAccountName string = storageAccount.name
output resourceId string = storageAccount.id
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
