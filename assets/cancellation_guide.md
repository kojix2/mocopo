# MocoPo Cancellation Guide

## Overview

The cancellation feature in MocoPo allows clients to cancel long-running operations. This guide explains how to use the cancellation functionality in your MCP server.

## Concepts

### Cancellation Token

A cancellation token is a unique identifier that can be used to cancel a long-running operation. Each token has:

- **ID**: A unique identifier for the token
- **Cancelled**: A boolean indicating whether the token has been cancelled
- **Reason**: An optional reason for the cancellation

### Cancellation Operations

The cancellation feature supports the following operations:

- **Create**: Create a new cancellation token
- **Cancel**: Cancel a token
- **Status**: Get the status of a token
- **List**: List all tokens

## API

### Cancellation Methods

MocoPo provides several cancellation methods:

- **cancellation/create**: Create a new cancellation token
- **cancellation/cancel**: Cancel a token
- **cancellation/status**: Get the status of a token
- **cancellation/list**: List all tokens

### Cancellation/Create Request

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "cancellation/create",
  "params": {
    "id": "my-token"
  }
}
```

The `id` parameter is optional. If not provided, a random ID will be generated.

### Cancellation/Create Response

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "id": "my-token",
    "cancelled": false
  }
}
```

### Cancellation/Cancel Request

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "cancellation/cancel",
  "params": {
    "id": "my-token",
    "reason": "User requested cancellation"
  }
}
```

The `reason` parameter is optional.

### Cancellation/Cancel Response

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "success": true
  }
}
```

### Cancellation/Status Request

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "cancellation/status",
  "params": {
    "id": "my-token"
  }
}
```

### Cancellation/Status Response

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "id": "my-token",
    "cancelled": true,
    "reason": "User requested cancellation"
  }
}
```

### Cancellation/List Request

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "cancellation/list"
}
```

### Cancellation/List Response

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": {
    "tokens": [
      {
        "id": "token1",
        "cancelled": false
      },
      {
        "id": "token2",
        "cancelled": true,
        "reason": "User requested cancellation"
      }
    ]
  }
}
```

## Using Cancellation with Tools

You can use cancellation tokens with tools to cancel long-running operations. Here's an example of a tool that supports cancellation:

```crystal
server.register_tool("longRunning", "A tool that simulates a long-running operation") do |tool|
  tool
    .argument_number("duration", true, "Duration in seconds")
    .argument_string("token", false, "Cancellation token ID")
    .on_execute do |args|
      # Get duration
      duration = args.try(&.["duration"]?.try(&.as_f?)) || 10.0
      
      # Get cancellation token ID
      token_id = args.try(&.["token"]?.try(&.as_s?))
      
      # Create a cancellation token if not provided
      if token_id.nil?
        token = server.create_cancellation_token
        token_id = token.id
      end
      
      # Simulate a long-running operation
      start_time = Time.monotonic
      result = "Operation completed successfully"
      
      # Check for cancellation every 0.1 seconds
      while Time.monotonic - start_time < Time::Span.new(seconds: duration.to_i, nanoseconds: (duration % 1 * 1_000_000_000).to_i)
        # Check if the operation has been cancelled
        if server.is_cancelled?(token_id)
          # Get the cancellation reason
          token = server.cancellation_manager.get_token(token_id)
          reason = token.try(&.reason) || "Unknown reason"
          
          # Return error
          return {
            "content" => [
              {
                "type" => "text",
                "text" => "Operation cancelled: #{reason}"
              }
            ] of Hash(String, String),
            "isError" => "true",
            "tokenId" => token_id
          }
        end
        
        # Sleep for a short time
        sleep 0.1
      end
      
      # Return success
      {
        "content" => [
          {
            "type" => "text",
            "text" => result
          }
        ] of Hash(String, String),
        "isError" => "false",
        "tokenId" => token_id
      }
    end
end
```

## Client-Side Usage

Here's an example of how a client might use the cancellation feature:

1. Create a cancellation token:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "cancellation/create",
  "params": {
    "id": "my-token"
  }
}
```

2. Start a long-running operation with the token:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "longRunning",
    "arguments": {
      "duration": 10,
      "token": "my-token"
    }
  }
}
```

3. Cancel the operation:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "cancellation/cancel",
  "params": {
    "id": "my-token",
    "reason": "User requested cancellation"
  }
}
```

## Best Practices

- **Token Management**: Clean up tokens that are no longer needed to avoid memory leaks.
- **Cancellation Checking**: Check for cancellation regularly in long-running operations.
- **Error Handling**: Handle cancellation gracefully and return appropriate error messages.
- **Cancellation Reasons**: Provide meaningful cancellation reasons to help clients understand why an operation was cancelled.
- **Token Sharing**: Consider sharing tokens between related operations to allow cancelling multiple operations at once.

## Example Server

See the `examples/cancellation_server.cr` file for a complete example of a server that supports cancellation.
