# MocoPo

A Crystal library for building MCP (Model Context Protocol) servers.

## Overview

MocoPo enables you to easily build MCP servers in Crystal.  
It is based on Kemal for high-performance and lightweight HTTP handling,  
and provides a DSL-style API for intuitive management and extension of tools, resources, and prompts.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     mocopo:
       github: your-github-user/mocopo
   ```

2. Run `shards install`

## Usage

```crystal
require "mocopo"

# Create a new MCP server
server = MocoPo::Server.new(
  name: "MyMCPServer",
  version: "1.0.0"
)

# Register a tool with arguments and execution callback
greet_tool = server.register_tool("greet", "Greet someone by name")
greet_tool
  .argument_string("name", true, "Name to greet")
  .on_execute do |args|
    name = args.try &.["name"]?.try &.as_s || "World"
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

# Start the server on port 3000
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

## Contributors

- [kojix2](https://github.com/your-github-user) - creator and maintainer
