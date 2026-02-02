#!/usr/bin/env python3
"""
Deploy a Hosted Agent to Microsoft Foundry
"""
import os
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import ImageBasedHostedAgentDefinition, ProtocolVersionRecord, AgentProtocol
from azure.identity import DefaultAzureCredential

from dotenv import load_dotenv
load_dotenv("../.env", override=True)

# Configuration - can be overridden by environment variables
PROJECT_ENDPOINT = os.environ.get("PROJECT_ENDPOINT", "")
AGENT_NAME =  os.environ.get("AGENT_NAME", "MyAgent")
CONTAINER_IMAGE = os.environ.get("CONTAINER_IMAGE", "")
APPINSIGHTS_CONNECTION_STRING = os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING", "")
PROJECT_NAME = os.environ.get("PROJECT_NAME", "")
ACCOUNT_NAME = os.environ.get("ACCOUNT_NAME", "")
AZURE_OPENAI_ENDPOINT = os.environ.get("AZURE_OPENAI_ENDPOINT", "")
AZURE_OPENAI_CHAT_DEPLOYMENT_NAME = os.environ.get("AZURE_OPENAI_CHAT_DEPLOYMENT_NAME", "gpt-5.2")
AZURE_AI_PROJECT_TOOL_CONNECTION_ID = os.environ.get("AZURE_AI_PROJECT_TOOL_CONNECTION_ID", "/subscriptions/06d043e2-5a2e-46bf-bf48-fffee525f377/resourceGroups/rg-foundry-hosted-agent/providers/Microsoft.CognitiveServices/accounts/foundryta3v6dfxutnwu/projects/hosted-agent/connections/mcp-connection")

def main():
    print(" Deploying AI Agent to Azure Foundry...")
    print(f"   Foundry: {ACCOUNT_NAME}")
    print(f"   Project: {PROJECT_ENDPOINT}")
    print(f"   Agent Name: {AGENT_NAME}")
    print(f"   Container Image: {CONTAINER_IMAGE}")
    print()

    # Initialize the client
    print(" Authenticating with Azure...")
    client = AIProjectClient(
        endpoint=PROJECT_ENDPOINT,
        credential=DefaultAzureCredential()
    )

    # Create the agent from container image
    print(" Creating hosted agent version...")
    agent = client.agents.create_version(
        agent_name=AGENT_NAME,
        definition=ImageBasedHostedAgentDefinition(
            container_protocol_versions=[
                ProtocolVersionRecord(protocol=AgentProtocol.RESPONSES, version="v1")
            ],
            cpu="3.5",
            memory="7Gi",
            image=CONTAINER_IMAGE, 
            environment_variables={
                "AZURE_OPENAI_ENDPOINT": AZURE_OPENAI_ENDPOINT,
                "AZURE_OPENAI_CHAT_DEPLOYMENT_NAME": AZURE_OPENAI_CHAT_DEPLOYMENT_NAME,
                "APPLICATIONINSIGHTS_CONNECTION_STRING": APPINSIGHTS_CONNECTION_STRING,
                "AZURE_AI_PROJECT_ENDPOINT": PROJECT_ENDPOINT,
                "AZURE_AI_PROJECT_TOOL_CONNECTION_ID": AZURE_AI_PROJECT_TOOL_CONNECTION_ID
            }
        )
    )

    print()
    print(" Agent version created successfully!")
    print(f"   Agent ID: {agent.id}")
    print(f"   Agent Name: {agent.name}")
    print(f"   Agent Version: {agent.version}")
    print()

    # Output version for shell script to capture
    print(f"AGENT_VERSION={agent.version}")

if __name__ == "__main__":
    main()
