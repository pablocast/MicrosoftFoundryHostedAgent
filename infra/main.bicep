targetScope = 'resourceGroup'

@description('Main location for the resources. Check https://learn.microsoft.com/en-us/azure/ai-foundry/agents/concepts/hosted-agents?view=foundry&tabs=cli#region-availability for supported regions.')
param location string

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

var tags = {
  'azd-env-name': environmentName
}

var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName, location))

resource acr 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: 'acr${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

resource foundry 'Microsoft.CognitiveServices/accounts@2025-10-01-preview' = {
  name: 'foundry${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: 'foundry${resourceToken}'
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }

  resource project 'projects' = {
    name:'hosted-agent'
    location: location
    tags: tags
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      description: 'Hosted Agent Demo Project'
      displayName: 'Hosted Agent Demo'
    }
  }

  // Comment this line if it causes an Internal Server Error when re-deploying the Bicep template.
  resource agentsCapabilityHost 'capabilityHosts' = {
    name: 'agents'
    properties: {
      capabilityHostKind: 'Agents'
      #disable-next-line BCP037
      enablePublicHostingEnvironment: true
    }
  }
}

resource aiFoundryProjectCanPullFromAcr 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(acr.id, foundry::project.id, acrPullRoleDefinition.id)
  properties: {
    roleDefinitionId: acrPullRoleDefinition.id
    principalId: foundry::project.identity.principalId
    principalType: 'ServicePrincipal'
    description: 'Allow AI Foundry Project to pull images from ACR'
  }
}

resource currentUserCanPushToAcr 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(acr.id, deployer().objectId, acrPushRoleDefinition.id)
  properties: {
    roleDefinitionId: acrPushRoleDefinition.id
    principalId: deployer().objectId
    principalType: 'User'
    description: 'Allow deployer to push images to ACR'
  }
}

resource currentUserCanPerformDataActionsOnFoundry 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: foundry
  name: guid(foundry.id, deployer().objectId, azureAiUserRoleDefinition.id)
  properties: {
    roleDefinitionId: azureAiUserRoleDefinition.id
    principalId: deployer().objectId
    principalType: 'User'
    description: 'Allow deployer to perfom Data actions on Foundry resource'
  }
}

@description('This is the built-in ACR Pull role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/containers#acrpull')
resource acrPullRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

@description('This is the built-in ACR Push role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/containers#acrpush')
resource acrPushRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '8311e382-0749-4cb8-b61a-304f252e45ec'
}

@description('This is the built-in Azure AI User role. See https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/rbac-azure-ai-foundry?view=foundry#azure-ai-user')
resource azureAiUserRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '53ca6127-db72-4b80-b1b0-d745d6d5456d'
}

output AZURE_PROJECT_ID string = foundry::project.id
output AZURE_PROJECT_ENDPOINT string = foundry::project.properties.endpoints['AI Foundry API']
output AZURE_ACR_LOGIN_SERVER string = acr.properties.loginServer
output AZURE_ACR_NAME string = acr.name
output AZURE_FOUNDRY_ACCOUNT_NAME string = foundry.name
output AZURE_PROJECT_NAME string = foundry::project.name
output AZURE_OPENAI_ENDPOINT string = foundry.properties.endpoints['OpenAI Language Service']
output AZURE_OPENAI_CHAT_DEPLOYMENT_NAME string = models
