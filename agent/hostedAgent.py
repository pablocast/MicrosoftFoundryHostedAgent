import os
from agent_framework import ChatAgent
from agent_framework.openai import AzureOpenAIChatClient
from azure.ai.agentserver.agentframework import from_agent_framework, FoundryToolsChatMiddleware
from azure.identity import DefaultAzureCredential
from asyncio import tools

def main() -> None:
    # Validate required environment variables
    required_env_vars = [
        "AZURE_OPENAI_ENDPOINT",
        "AZURE_OPENAI_CHAT_DEPLOYMENT_NAME",
    ]
    for env_var in required_env_vars:
        assert env_var in os.environ and os.environ[env_var], (
            f"{env_var} environment variable must be set."
        )

    # Configure tools for the agent
    tools=[{"type": "web_search_preview"}]
    if project_tool_connection_id := os.environ.get("AZURE_AI_PROJECT_TOOL_CONNECTION_ID"):
        tools.append({"type": "mcp", "project_connection_id": project_tool_connection_id})

    # Create the chat client with Foundry tools middleware
    chat_client = AzureOpenAIChatClient(
        credential=DefaultAzureCredential(),
        middleware=FoundryToolsChatMiddleware(tools)
    )
    
    agent = chat_client.create_agent(
        name="FoundryToolAgent",
        instructions="You are a helpful assistant with access to various tools."
    )

    # Use the agent server adapter to host the agent
    # This automatically creates a REST API on port 8088 with /responses endpoint
    from_agent_framework(agent).run()

if __name__ == "__main__":
    main()
