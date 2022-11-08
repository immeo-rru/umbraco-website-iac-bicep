// Create Redis
// https://gist.github.com/JonCole/925630df72be1351b21440625ff2671f#file-redis-bestpractices-md

param applicationName string
@allowed([
  'dev'
  'test'
  'prod'
])
param deploymentEnvironment string
param location string = resourceGroup().location
param appName string = 'redis-${applicationName}-${deploymentEnvironment}-${location}'

resource redis 'Microsoft.Cache/redis@2021-06-01' = {
  name: appName
  location: location
  properties: {
    sku: {
      name: 'Basic'
      family: 'C'
      capacity: 0
    }
    redisVersion: '6'
    redisConfiguration: {
      
    }
  }
}

output redisPrimaryKey string = redis.properties.accessKeys.primaryKey
output redisSecondaryKey string = redis.properties.accessKeys.secondaryKey
output appName string = appName
