# MocoPo Sampling Guide

## Overview

The sampling feature in MocoPo allows servers to request LLM completions through the client with human-in-the-loop review for security and safety. This guide explains how to use the sampling functionality in your MCP server.

## Message Flow

1. **Client sends a request to the server**: The client sends a request to the server, which may require LLM assistance to fulfill.
2. **Server requests LLM completion**: The server sends a `sampling/createMessage` request to the client.
3. **Client reviews the prompt**: The client reviews the prompt for security and safety.
4. **Client sends the prompt to an LLM**: The client sends the prompt to an LLM and receives a response.
5. **Client reviews the response**: The client reviews the response for security and safety.
6. **Client sends the response to the server**: The client sends the approved response back to the server.
7. **Server uses the response**: The server uses the response to fulfill the client's original request.

## API

### Sampling Methods

MocoPo provides several sampling methods:

- **greedy**: Selects the token with the highest probability.
- **temperature**: Performs probabilistic sampling using a temperature parameter.
- **top_k**: Selects from the top k tokens.
- **top_p**: Selects from tokens until the cumulative probability exceeds p.

### Sampling Request

A sampling request includes:

- **messages**: An array of messages, each with a role and content.
- **modelPreferences**: Optional preferences for the model to use.
- **systemPrompt**: Optional system prompt to provide context.
- **includeContext**: Optional flag to include context from the server.
- **temperature**: Optional temperature parameter for sampling.
- **maxTokens**: Maximum number of tokens to generate.
- **stopSequences**: Optional array of sequences that will stop generation.
- **metadata**: Optional metadata to include with the request.

### Sampling Response

A sampling response includes:

- **role**: The role of the message (usually "assistant").
- **content**: The content of the message.
- **model**: The model used to generate the response.
- **stopReason**: The reason why generation stopped.

## Example Usage

```crystal
# Create a sampling request
request = MocoPo::SamplingRequest.new(
  messages: [MocoPo::SamplingMessage.user_text("What is the capital of France?")],
  max_tokens: 100
)

# Create a context
context = MocoPo::Context.new("request-1", "client-1", server)

# Create a message
response = server.sampling_manager.create_message(request, context)

# Use the response
puts response.content.text
```

## Best Practices

- **Review prompts and responses**: Always review prompts and responses for security and safety.
- **Use system prompts**: Use system prompts to provide context and guide the LLM.
- **Set appropriate max_tokens**: Set an appropriate max_tokens value to avoid generating too much text.
- **Use stop sequences**: Use stop sequences to stop generation at appropriate points.

## Security Considerations

- **Prompt injection**: Be aware of prompt injection attacks and review prompts carefully.
- **Data leakage**: Be careful not to include sensitive data in prompts.
- **Response validation**: Validate responses before using them.
