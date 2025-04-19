# MocoPo Transport Layer Guide

This guide explains how to use the transport layer in MocoPo, which provides a flexible way to communicate between MCP clients and servers.

## Overview

The transport layer in MocoPo is responsible for handling the communication between clients and servers. It provides a common interface for different transport mechanisms, such as HTTP, stdio, and SSE (Server-Sent Events).

## Transport Types

MocoPo supports the following transport types:

### HTTP Transport

The HTTP transport uses HTTP POST requests for communication. It's suitable for web-based applications and is the default transport used by MocoPo.

```crystal
# Create an HTTP transport
http_transport = server.create_http_transport
```

### Stdio Transport

The stdio transport uses standard input and output for communication. It's suitable for command-line tools and local integrations.

```crystal
# Create a stdio transport
stdio_transport = server.create_stdio_transport
```

### SSE Transport

The SSE (Server-Sent Events) transport uses HTTP GET requests with SSE for server-to-client communication and HTTP POST requests for client-to-server communication. It's suitable for scenarios where server-to-client streaming is needed.

```crystal
# Create an SSE transport
sse_transport = server.create_sse_transport
```

## Using Multiple Transports

MocoPo allows you to use multiple transports simultaneously. This is useful when you want to support different communication mechanisms for different clients.

```crystal
# Create and register multiple transports
http_transport = server.create_http_transport
stdio_transport = server.create_stdio_transport
sse_transport = server.create_sse_transport

# Start the server (starts all transports)
server.start
```

## Custom Transports

You can create custom transports by implementing the `Transport` abstract class. This allows you to support additional communication mechanisms not provided by MocoPo.

```crystal
class MyCustomTransport < MocoPo::Transport
  # Implement the required methods
  def start : Nil
    # Start the transport
  end

  def send(message : MocoPo::JsonObject) : Nil
    # Send a message
  end

  def close : Nil
    # Close the transport
  end
end

# Register the custom transport
custom_transport = MyCustomTransport.new
server.register_transport(custom_transport)
```

## Transport Manager

The transport manager is responsible for managing all registered transports. It provides methods for registering, starting, and closing transports.

```crystal
# Get the transport manager
transport_manager = server.transport_manager

# Register a transport
transport_manager.register(my_transport)

# Start all transports
transport_manager.start_all

# Close all transports
transport_manager.close_all
```

## Example

Here's a complete example of using multiple transports:

```crystal
require "mocopo"

# Create a new MCP server
server = MocoPo::Server.new("multi-transport-server", "1.0.0")

# Register a simple tool
server.register_tool("echo", "Echo the input") do |tool|
  tool.add_parameter("message", "Message to echo", "string", required: true)
  tool.handler = ->(params : MocoPo::JsonObject) {
    message = params["message"]?.try &.as_s || "No message provided"
    {"message" => message}
  }
end

# Create and register transports
http_transport = server.create_http_transport
stdio_transport = server.create_stdio_transport
sse_transport = server.create_sse_transport

puts "Starting MCP server with multiple transports:"
puts "- HTTP transport: POST to /mcp"
puts "- SSE transport: GET /sse for server-to-client, POST to /messages for client-to-server"
puts "- stdio transport: Reading from stdin, writing to stdout"

# Start the server
server.start
```

## Best Practices

- Use the appropriate transport for your use case:
  - HTTP for web-based applications
  - stdio for command-line tools and local integrations
  - SSE for scenarios where server-to-client streaming is needed
- Consider security implications when using different transports
- Handle errors gracefully in your transport implementations
- Clean up resources when closing transports
