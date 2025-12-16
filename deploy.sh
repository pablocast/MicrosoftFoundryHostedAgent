#!/bin/bash
set -e

RESOURCE_GROUP="hosted-agents"
LOCATION="northcentralus"
FOUNDRY_NAME="hosted-agents-ati1"
PROJECT_NAME="hosted-agents"
ACR_NAME="hostedagentsati1"
IMAGE_TAG="v1"
AGENT_NAME="myagent"

az login

echo "🚀 Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

echo "🚀 Deploying infrastructure..."
DEPLOYMENT_OUTPUT=$(az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file infra/main.bicep \
  --parameters foundryAccountName=$FOUNDRY_NAME \
               projectName=$PROJECT_NAME \
               acrName=$ACR_NAME \
               location=$LOCATION \
  --query 'properties.outputs' -o json)

PROJECT_ID=$(echo $DEPLOYMENT_OUTPUT | jq -r '.projectId.value')
PROJECT_ENDPOINT=$(echo $DEPLOYMENT_OUTPUT | jq -r '.projectEndpoint.value')
ACR_LOGIN_SERVER=$(echo $DEPLOYMENT_OUTPUT | jq -r '.acrLoginServer.value')

echo "✅ Infrastructure deployed"
echo "📦 Building and pushing container..."

CONTAINER_IMAGE="${ACR_LOGIN_SERVER}/myagent:${IMAGE_TAG}"
az acr build \
  --registry $ACR_NAME \
  --image myagent:$IMAGE_TAG \
  --file ./agent/Dockerfile \
  ./agent/

echo "✅ Container built and pushed"
echo "🤖 Deploying agent..."

export PROJECT_ENDPOINT=$PROJECT_ENDPOINT
export AGENT_NAME=$AGENT_NAME
export CONTAINER_IMAGE=$CONTAINER_IMAGE
export PROJECT_NAME=$PROJECT_NAME
export ACCOUNT_NAME=$FOUNDRY_NAME

DEPLOY_OUTPUT=$(cd ./infra && uv sync && uv run deploy_foundry_hosted_agent.py)
echo "$DEPLOY_OUTPUT"

# Extract agent version from output
AGENT_VERSION=$(echo "$DEPLOY_OUTPUT" | grep "^AGENT_VERSION=" | cut -d'=' -f2)

echo "▶️  Starting agent version: $AGENT_VERSION"
az cognitiveservices agent start \
  --account-name $FOUNDRY_NAME \
  --project-name $PROJECT_NAME \
  --name $AGENT_NAME \
  --agent-version $AGENT_VERSION

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Project Endpoint: $PROJECT_ENDPOINT"
echo "🏷️  Agent Name: $AGENT_NAME"
echo "📦 Container Image: $CONTAINER_IMAGE"
echo "🔢 Agent Version: $AGENT_VERSION"
echo ""
PROJECT_ID_ENCODED=$(echo -n "$PROJECT_ID" | base64 -w 0 | tr '+/' '-_' | tr -d '=')
echo "🌐 View in portal: https://ai.azure.com/nextgen/r/${PROJECT_ID_ENCODED},${RESOURCE_GROUP},,${FOUNDRY_NAME},${PROJECT_NAME}/build/agents/${AGENT_NAME}/build?version=${AGENT_VERSION}"
