# MocoPo

⚠️ WARNING VIBE CODING ⚠️

A Crystal library for building MCP (Model Context Protocol) servers.

## Overview

MocoPo enables you to easily build MCP servers in Crystal.  
It provides a flexible transport layer supporting multiple communication methods (HTTP, SSE, stdio),  
and offers a DSL-style API for intuitive management of tools, resources, and prompts.

The library uses Kemal for HTTP handling but abstracts communication through a transport layer,  
allowing for different communication mechanisms to be used interchangeably.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     mocopo:
       github: your-github-user/mocopo
   ```

2. Run `shards install`

## Features

- **Multiple Transport Support**:

  - HTTP transport for web-based applications
  - SSE (Server-Sent Events) transport for real-time notifications
  - stdio transport for command-line tools and local integrations
  - Extensible architecture for custom transports

- **Tool Management**:

  - Register and manage tools with rich argument schemas
  - Support for nested arguments, arrays, and objects
  - Execution callbacks with context

- **Resource Management**:

  - URI-based resource registration
  - Content providers with dynamic generation
  - MIME type support

- **Notification System**:

  - Real-time notifications across all transports
  - List change notifications for tools, resources, and prompts
  - Resource update notifications

- **Consistent JSON Handling**:
  - Uses `JsonValue` type consistently throughout the codebase
  - Type-safe JSON handling with clear interfaces
  - Utility functions for converting between `JsonValue` and Crystal's `JSON::Any` when needed
  - Simplified JSON schema generation and validation

## Usage

```crystal
require "mocopo"

# Create a new MCP server
server = MocoPo::Server.new(
  name: "MyMCPServer",
  version: "1.0.0"
)

# By default, HTTP transport is created automatically
# You can create additional transports as needed
stdio_transport = server.create_stdio_transport
sse_transport = server.create_sse_transport

# Register a tool with arguments and execution callback
greet_tool = server.register_tool("greet", "Greet someone by name")
greet_tool
  .argument_string("name", true, "Name to greet")
  .on_execute do |args|
    # args is a JsonObject (Hash(String, JsonValue))
    name = "World"
    if args && args["name"]?
      name_value = args["name"]
      name = name_value.is_a?(String) ? name_value : name_value.to_s
    end

    {
      "content" => [
        {
          "type" => "text",
          "text" => "Hello, #{name}!"
        }
      ] of Hash(String, String),
      "isError" => "false"
    }
  end

# Register a resource with content callback
readme_resource = server.register_resource(
  uri: "file:///readme",
  name: "README",
  description: "Project README file",
  mime_type: "text/markdown"
)
readme_resource.on_read do
  MocoPo::ResourceContent.text(
    uri: "file:///readme",
    text: "# My MCP Server\n\nThis is a sample README.",
    mime_type: "text/markdown"
  )
end

# Start the server on port 3000 (starts all transports)
server.start
```

For more examples, see the [examples](examples/) directory.

## Development

- Use Crystal's built-in Spec framework for testing
- Generate documentation with `crystal doc`

## Contributing

1. Fork it (<https://github.com/your-github-user/mocopo/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
