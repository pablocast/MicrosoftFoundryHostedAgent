#!/bin/bash
set -e

echo "📦 Building and pushing container..."

IMAGE_TAG="${AZURE_ENV_NAME:-v1}"
CONTAINER_IMAGE="${AZURE_ACR_LOGIN_SERVER}/myagent:${IMAGE_TAG}"

# Set encoding to handle Unicode characters in Azure CLI output on Windows
export PYTHONIOENCODING=utf-8

az acr build \
  --registry "${AZURE_ACR_NAME}" \
  --image "myagent:${IMAGE_TAG}" \
  --file ./agent/Dockerfile \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --no-logs \
  ./agent/

# Wait for the build to complete and check status
echo "⏳ Waiting for ACR build to complete..."
sleep 10

echo "✅ Container built and pushed"
echo "🤖 Deploying agent..."

export PROJECT_ENDPOINT="${AZURE_PROJECT_ENDPOINT}"
export AGENT_NAME="${AZURE_AGENT_NAME:-myagent}"
export CONTAINER_IMAGE="${CONTAINER_IMAGE}"
export PROJECT_NAME="${AZURE_PROJECT_NAME}"
export ACCOUNT_NAME="${AZURE_FOUNDRY_ACCOUNT_NAME}"
export AZURE_OPENAI_ENDPOINT="${AZURE_OPENAI_ENDPOINT}"
export AZURE_OPENAI_CHAT_DEPLOYMENT_NAME="${AZURE_OPENAI_CHAT_DEPLOYMENT_NAME}"
export APPLICATIONINSIGHTS_CONNECTION_STRING="${APPLICATIONINSIGHTS_CONNECTION_STRING}"
export AZURE_AI_PROJECT_TOOL_CONNECTION_ID="${AZURE_AI_PROJECT_TOOL_CONNECTION_ID}"

# Creat .env file for uv
echo "Creating .env file for deployment..."
cat > .env <<EOL
AZURE_OPENAI_ENDPOINT=${AZURE_OPENAI_ENDPOINT}
AZURE_OPENAI_CHAT_DEPLOYMENT_NAME=${AZURE_OPENAI_CHAT_DEPLOYMENT_NAME}
APPLICATIONINSIGHTS_CONNECTION_STRING=${APPLICATIONINSIGHTS_CONNECTION_STRING}
PROJECT_ENDPOINT=${PROJECT_ENDPOINT}
AZURE_AI_PROJECT_TOOL_CONNECTION_ID=${AZURE_AI_PROJECT_TOOL_CONNECTION_ID}
EOL

DEPLOY_OUTPUT=$(cd scripts && uv sync && uv run deploy_foundry_hosted_agent.py)
echo "$DEPLOY_OUTPUT"

# Extract agent version from output
AGENT_VERSION=$(echo "$DEPLOY_OUTPUT" | grep "^AGENT_VERSION=" | cut -d'=' -f2)

echo "▶️  Starting agent version: $AGENT_VERSION"
az cognitiveservices agent start \
  --account-name "${AZURE_FOUNDRY_ACCOUNT_NAME}" \
  --project-name "${AZURE_PROJECT_NAME}" \
  --name "${AGENT_NAME}" \
  --agent-version "${AGENT_VERSION}"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Project Endpoint: ${PROJECT_ENDPOINT}"
echo "🏷️  Agent Name: ${AGENT_NAME}"
echo "📦 Container Image: ${CONTAINER_IMAGE}"
echo "🔢 Agent Version: ${AGENT_VERSION}"
echo ""
PROJECT_ID_ENCODED=$(echo -n "${AZURE_PROJECT_ID}" | base64 -w 0 | tr '+/' '-_' | tr -d '=')
echo "🌐 View in portal: https://ai.azure.com/nextgen/r/${PROJECT_ID_ENCODED},${AZURE_RESOURCE_GROUP},,${AZURE_FOUNDRY_ACCOUNT_NAME},${AZURE_PROJECT_NAME}/build/agents/${AGENT_NAME}/build?version=${AGENT_VERSION}"
