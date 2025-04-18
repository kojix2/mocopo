# MocoPo Completion Guide

## Overview

This guide explains the completion support in MocoPo for providing autocompletion suggestions for prompt and resource arguments. Completion allows clients to get contextual suggestions while entering argument values, enabling rich, IDE-like experiences.

## Completion Model

MocoPo implements completion as specified in the Model Context Protocol (MCP). This approach allows clients to request completion suggestions for arguments based on the current input value.

Key features:
- Supports completion for both prompt and resource arguments
- Returns ranked suggestions based on relevance
- Includes metadata like total matches and whether more results are available
- Implements rate limiting and input validation for security

## Supported Operations

The following operations support completion:

- `completion/complete` - Get completion suggestions for an argument

## How to Use Completion

### Client-Side

When making a request to the completion endpoint, clients need to provide a reference to what is being completed and the current argument value:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "completion/complete",
  "params": {
    "ref": {
      "type": "ref/prompt",
      "name": "code_review"
    },
    "argument": {
      "name": "language",
      "value": "py"
    }
  }
}
```

The server will respond with completion suggestions:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "completion": {
      "values": ["python", "pytorch"],
      "total": 2,
      "hasMore": false
    }
  }
}
```

### Server-Side

Server implementations using MocoPo automatically get completion support. The completion is handled by the `Completion` module, which provides utilities for generating completion suggestions.

## Implementation Details

### Reference Types

The completion API supports two types of references:

1. **Prompt References**: Used to complete arguments for prompts
   ```json
   {
     "type": "ref/prompt",
     "name": "prompt_name"
   }
   ```

2. **Resource References**: Used to complete arguments for resources
   ```json
   {
     "type": "ref/resource",
     "uri": "resource_uri"
   }
   ```

### Completion Module

The `Completion` module provides the following functionality:

- `Reference` class for managing reference information
- `Argument` class for managing argument information
- `Result` class for managing completion results
- `complete` method for generating completion suggestions

Example usage:

```crystal
# Create a reference
ref = Completion::Reference.new(Completion::ReferenceType::Prompt, "code_review")

# Create an argument
arg = Completion::Argument.new("language", "py")

# Get completion suggestions
result = Completion.complete(ref, arg, server)

# Return completion results
{
  "completion" => result.to_json_object
}
```

## Example Server

See `examples/completion_server.cr` for a complete example of a server that demonstrates completion for prompt and resource arguments.

To run the example:

```
crystal examples/completion_server.cr
```

This will start a server on http://localhost:3000 and demonstrate completion by making requests to complete prompt and resource arguments.

## Security Considerations

The completion implementation includes several security features:

1. **Input Validation**: All input parameters are validated before processing
2. **Rate Limiting**: Requests are rate-limited to prevent abuse
3. **Access Control**: The completion handler can be extended to implement access control
4. **Error Handling**: Proper error handling is implemented to prevent information disclosure

## Best Practices

1. **Debounce Requests**: Clients should debounce rapid completion requests to avoid overwhelming the server
2. **Cache Results**: Clients should cache completion results where appropriate
3. **Provide Context**: Servers should use context to provide more relevant suggestions
4. **Implement Fuzzy Matching**: Servers should implement fuzzy matching for better user experience
5. **Limit Results**: Servers should limit the number of results to avoid performance issues
