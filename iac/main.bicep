// 1. Log in to your tenant
//    az login --tenant [xxxxx].onmicrosoft.com
//
// 2. Dry-run, does not create - deployment with "what if"
//    az deployment group what-if --resource-group changethis --template-file ./iac/main.bicep --parameters applicationName=changethis deploymentEnvironment=test
//
// 3. If all went ok - create ressources. This will take a few moments
//    az deployment group create --resource-group changethis --template-file ./iac/main.bicep --parameters applicationName=changethis deploymentEnvironment=test -c
//
// Parameters
// what-if = show consequences but does not perform
// -c = runs what-if before executing

param deploymentEnvironment string
param applicationName string
param location string = resourceGroup().location
param adGroupsChangeThisId string // todo + changethis: Here for demo reason; otherwise param should be removed. 

// ------------------------------------------------------------------
// Storage
// ------------------------------------------------------------------
module stgModule './create-storage.bicep' = {
  name: 'storageWebShop'
  params: {
    applicationName: applicationName
    deploymentEnvironment: deploymentEnvironment
    location: location
  }
}

// ------------------------------------------------------------------
// application insight
// ------------------------------------------------------------------
module appInsight 'create-application-insight.bicep' = {
  name: 'appInsight'
  params: {
    applicationName: applicationName
    deploymentEnvironment: deploymentEnvironment
    location: location
  }
}

// ------------------------------------------------------------------
// Identity
// ------------------------------------------------------------------
module identity 'create-identity.bicep' = {
  name: 'identity'
  params: {
    applicationName: applicationName
    deploymentEnvironment: deploymentEnvironment
    location: location
  }
}

// ------------------------------------------------------------------
// Keyvault
// ------------------------------------------------------------------
module keyVault 'create-keyvault.bicep' = {
  name: 'keyVault'
  params: {
    applicationName: applicationName
    deploymentEnvironment: deploymentEnvironment
    location: location
    defaultAccessPolicyAdminGroupObjectId: adGroupsChangeThisId
    accessPolicies:  [
      {
        objectId: identity.outputs.principalId
        readOnly: false
      }
    ]
  }
}

// ------------------------------------------------------------------
// database server, elastic pool, databases
// ------------------------------------------------------------------
module dbModule 'create-database.bicep' = {
  name: 'dbModule'
  params: {
    applicationName: applicationName
    deploymentEnvironment: deploymentEnvironment
    location: location
    adGroupsChangeThisId: adGroupsChangeThisId
    sqlDbLogInChangeThis: adGroupsChangeThisId
  }
}

// ------------------------------------------------------------------
// Redis
// ------------------------------------------------------------------
// module redis 'create-redis.bicep' = {
//   name: 'redis'
//   params: {
//     applicationName: applicationName
//     deploymentEnvironment: deploymentEnvironment
//     location: location
//   }
// }

// ------------------------------------------------------------------
// Keyvault secret
// ------------------------------------------------------------------
module keyVaultSecret 'create-keyvault-secret.bicep' = {
  name: 'keyVaultSecret'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'Environment'
    secretValue: deploymentEnvironment
  }
}

// ------------------------------------------------------------------
// App service plan - back office
// ------------------------------------------------------------------
var planValuesBackOffice = {
  dev: {
      sku: 'B1'
      skuCapacity: 1
    }
  test: {
      sku: 'B1'
      skuCapacity: 1
    }
  prod: {
      sku: 'P1V2'
      skuCapacity: 1
    }
}

// service plan for backoffice (bo)
module appSvcPlan 'create-appserviceplan.bicep' = {
  name: 'appSvcPlan'
  params: {
    applicationName: applicationName
    postFixName: '-bo'
    location: location
    deploymentEnvironment: deploymentEnvironment
    skuName: planValuesBackOffice[deploymentEnvironment].sku
    skuCapacity: planValuesBackOffice[deploymentEnvironment].skuCapacity
  }  
}  

// webapp for backoffice (bo)
module webAppModule 'create-web-app.bicep' = {
  name: 'webAppModuleBackOffice'
  params: {
    deploymentEnvironment: deploymentEnvironment
    applicationName: applicationName
    postFixName: '-bo'
    location: location
    keyVaultUri: keyVault.outputs.vaultUri
    websiteRegistrar: 'main'
  }    
}  

module functionAppModule 'create-function-app.bicep' = {
  name: 'functionAppModuleBackOffice'
  params: {
    deploymentEnvironment: deploymentEnvironment
    applicationName: applicationName
    postFixName: '-bo'
    location: location
    appInsightsInstrumentationKey: appInsight.outputs.instrumentationKey
    keyVaultUri: keyVault.outputs.vaultUri
    storageAccountConnectionString: stgModule.outputs.connectionString
  }    
}  

// ------------------------------------------------------------------
// App service plan - Web
// ------------------------------------------------------------------
var planValuesWeb = {
  dev: {
      sku: 'B1' // B1 is here for demo purposes
      skuCapacity: 1
    }
  test: {
      sku: 'B1' // B1 is here for demo purposes
      skuCapacity: 1
    }
  prod: {
      sku: 'P2V2'
      skuCapacity: 1
    }
}

// service plan - web
module appSvcPlanWeb 'create-appserviceplan.bicep' = {
  name: 'appSvcPlanWeb'
  params: {
    applicationName: applicationName
    postFixName: '-web'
    deploymentEnvironment: deploymentEnvironment
    location: location
    skuName: planValuesWeb[deploymentEnvironment].sku
    skuCapacity: planValuesWeb[deploymentEnvironment].skuCapacity
  }  
}  

// webapp + slot - Web
module webAppModuleWeb 'create-web-app.bicep' = {
  name: 'webAppModuleWeb'
  params: {
    deploymentEnvironment: deploymentEnvironment
    applicationName: applicationName
    postFixName: '-web'
    location: location
    keyVaultUri: keyVault.outputs.vaultUri
    websiteRegistrar: 'replica'
    siteAlwaysOn: true
  }    
}
