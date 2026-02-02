#!/usr/bin/env python3
"""
Deploy a Hosted Agent to Microsoft Foundry
"""
import os
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import ImageBasedHostedAgentDefinition, ProtocolVersionRecord, AgentProtocol
from azure.identity import DefaultAzureCredential

# Configuration - can be overridden by environment variables
PROJECT_ENDPOINT = os.getenv("PROJECT_ENDPOINT", "")
AGENT_NAME =  os.getenv("AGENT_NAME", "MyAgent")
CONTAINER_IMAGE = os.getenv("CONTAINER_IMAGE", "")
APPINSIGHTS_CONNECTION_STRING = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING", "")
PROJECT_NAME = os.getenv("PROJECT_NAME", "")
ACCOUNT_NAME = os.getenv("ACCOUNT_NAME", "")
AZURE_OPENAI_ENDPOINT = os.getenv("AZURE_OPENAI_ENDPOINT", "")
AZURE_OPENAI_CHAT_DEPLOYMENT_NAME = os.getenv("AZURE_OPENAI_CHAT_DEPLOYMENT_NAME", "")
AZURE_AI_PROJECT_TOOL_CONNECTION_ID = os.getenv("AZURE_AI_PROJECT_TOOL_CONNECTION_ID", "")

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
