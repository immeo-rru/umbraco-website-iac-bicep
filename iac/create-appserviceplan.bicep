// Create Application service plan

param applicationName string
param postFixName string
@allowed([
  'dev'
  'test'
  'prod'
])
param deploymentEnvironment string
param skuName string
param skuCapacity int = 1
param location string = resourceGroup().location

var appServicePlanName = toLower('asp-${applicationName}-${deploymentEnvironment}-${location}${postFixName}')

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  tags: {
    displayName: 'HostingPlan'
    ProjectName: appServicePlanName
  }
}

