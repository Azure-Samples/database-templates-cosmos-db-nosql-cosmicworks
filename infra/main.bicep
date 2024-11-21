metadata description = 'Provisions resources for Azure SQL Database with AdventureWorks pre-installed'

targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention.')
param environmentName string

@minLength(1)
@description('Primary location for all resources.')
param location string

@description('Id of the principal to assign database and application roles.')
param deploymentUserPrincipalId string = ''

var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
  repo: 'https://github.com/azure-samples/database-templates-cosmos-db-nosql-cosmicworks'
}

module managedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'user-assigned-identity'
  params: {
    name: 'managed-identity-${resourceToken}'
    location: location
    tags: tags
  }
}

module nosql 'br/public:avm/res/document-db/database-account:0.8.1' = {
  name: 'cosmos-db-nosql-account'
  params: {
    name: 'cosmos-db-nosql-${resourceToken}'
    location: location
    tags: tags
    locations: [
      {
        failoverPriority: 0
        locationName: location
        isZoneRedundant: false
      }
    ]
    disableKeyBasedMetadataWriteAccess: false
    disableLocalAuth: false
    networkRestrictions: {
      publicNetworkAccess: 'Enabled'
      ipRules: []
      virtualNetworkRules: []
    }
    capabilitiesToAdd: [
      'EnableServerless'
    ]
    sqlRoleDefinitions: [
      {
        name: 'nosql-data-plane-contributor'
        dataAction: [
          'Microsoft.DocumentDB/databaseAccounts/readMetadata'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
        ]
      }
    ]
    sqlRoleAssignmentsPrincipalIds: union(
      [
        managedIdentity.outputs.principalId
      ],
      !empty(deploymentUserPrincipalId) ? [deploymentUserPrincipalId] : []
    )
    sqlDatabases: [
      {
        name: 'cosmicworks'
        containers: [
          {
            name: 'products'
            paths: [
              '/category/name'
              '/category/subCategory/name'
            ]
            kind: 'MultiHash'
            version: 2
            indexingPolicy: {
              automatic: true
              indexingMode: 'consistent'
              includedPaths: [
                {
                  path: '/*'
                }
              ]
              excludedPaths: [
                {
                  path: '/_etag/?'
                }
              ]
              compositeIndexes: [
                [
                  {
                    path: '/caategory/name'
                    order: 'ascending'
                  }
                  {
                    path: '/category/subCategory/name'
                    order: 'ascending'
                  }
                ]
              ]
            }
          }
          {
            name: 'employees'
            paths: [
              '/company'
              '/department'
              '/territory'
            ]
            kind: 'MultiHash'
            version: 2
            indexingPolicy: {
              automatic: true
              indexingMode: 'consistent'
              includedPaths: [
                {
                  path: '/*'
                }
              ]
              excludedPaths: [
                {
                  path: '/_etag/?'
                }
              ]
              compositeIndexes: [
                [
                  {
                    path: '/company'
                    order: 'ascending'
                  }
                  {
                    path: '/department'
                    order: 'ascending'
                  }
                ]
                [
                  {
                    path: '/company'
                    order: 'ascending'
                  }
                  {
                    path: '/department'
                    order: 'ascending'
                  }
                  {
                    path: '/territory'
                    order: 'ascending'
                  }
                ]
              ]
            }
          }
        ]
      }
    ]
  }
}

module script 'br/public:avm/res/resources/deployment-script:0.5.0' = {
  name: 'deployment-script-seed-data'
  params: {
    name: 'deployment-script-${resourceToken}'
    location: location
    tags: tags
    kind: 'AzurePowerShell'
    azPowerShellVersion: '12.3'
    managedIdentities: {
      userAssignedResourceIds: [
        managedIdentity.outputs.resourceId
      ]
    }
    environmentVariables: [
      {
        name: 'AZURE_COSMOS_DB_NOSQL_ACCOUNT_ENDPOINT'
        secureValue: nosql.outputs.endpoint
      }
    ]
    timeout: 'PT12M'
    scriptContent: '''
      apt-get update
      apt-get install --yes dotnet-sdk-8.0
      dotnet new tool-manifest --name dotnet-tools.json
      dotnet tool install cosmicworks --version 2.3.1
      dotnet cosmicworks --role-based-access-control --endpoint "${Env:AZURE_COSMOS_DB_NOSQL_ACCOUNT_ENDPOINT}"
    '''
  }
}
