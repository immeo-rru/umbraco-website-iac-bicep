// Create key vault secret

@description('Name of the keyvault.')
param keyVaultName string

@description('Name for the secret.')
param secretName string

@description('Value for the secret.')
@secure()
param secretValue string

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  name: '${keyVaultName}/${secretName}' 
  properties: {
    value: secretValue
  }
}
