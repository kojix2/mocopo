require "../src/mocopo"

# Create a new MCP server
server = MocoPo::Server.new(
  name: "SimpleMCPServer",
  version: "1.0.0"
)

# Register a sample tool
weather_tool = MocoPo::Tool.new(
  name: "get_weather",
  description: "Get current weather information for a location",
  input_schema: {
    "type"       => JSON::Any.new("object"),
    "properties" => JSON::Any.new({
      "location" => JSON::Any.new({
        "type"        => JSON::Any.new("string"),
        "description" => JSON::Any.new("City name or zip code"),
      }),
    }),
    "required" => JSON::Any.new([JSON::Any.new("location")]),
  }
)
server.tool_manager.register(weather_tool)

# Register a sample resource
readme_resource = MocoPo::Resource.new(
  uri: "file:///readme",
  name: "README",
  description: "Project README file",
  mime_type: "text/markdown"
)
server.resource_manager.register(readme_resource)

# Start the server on port 3000
puts "Starting MCP server on http://localhost:3000/mcp"
puts "Press Ctrl+C to stop"
puts "Registered tools: #{server.tool_manager.list.map(&.name).join(", ")}"
puts "Registered resources: #{server.resource_manager.list.map(&.name).join(", ")}"
server.start
