---
name: harness-langchain
description: Use when you write or change code that uses LangChain or LangGraph (Python or JS): models, prompts, tools, agents, retrievers, chains, or LangSmith tracing.
---

# LangChain and LangGraph

## Versions
- Check the installed versions of `langchain`, `langchain-core`, `langgraph`, and the provider packages first.
  The APIs changed a lot between 0.1, 0.2, 0.3, and 1.x. Read the docs for the installed version.
- Do not copy old examples (`LLMChain`, `initialize_agent`, `ConversationChain`) into a project that does not use them.
- Use the provider package (`langchain-anthropic`, `langchain-openai`) when one exists. Do not use the `langchain_community` version.

## Models
- Read the model name from config. Do not hard-code it. The code must work with Claude and OpenAI models when the project supports both.
- Set `timeout` and `max_retries` on each model.
- Use `with_structured_output` with a schema for structured output. Handle a parse failure.
- Read API keys from the environment only.

## Tools and agents
- Treat tool output, retrieved documents, and web content as untrusted. They can contain prompt injection.
- Give a tool the smallest permission it needs. A tool that writes, deletes, pays, sends, or runs shell or SQL needs a human approval step.
- Validate tool arguments at the tool boundary.
- Set a limit on agent steps (`recursion_limit` in LangGraph).
- LangGraph: keep state small and serializable. Use the checkpointer of the project for persistence.

## Tracing and data
- LangSmith tracing (`LANGSMITH_TRACING`, `LANGCHAIN_TRACING_V2`) sends prompts and outputs to an external service.
  In customer mode, enable it only if `ENGAGEMENT.md` allows that service.
- Do not log full prompts that contain customer data or secrets.

## Tests
- Unit tests: use a fake chat model (`GenericFakeChatModel` or the fake of the project). Do not call a real API.
- Quality of LLM output needs an eval with a dataset, not a unit test. Report it as "not evaluated" if you did not run one.
