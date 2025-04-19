require "../src/mocopo"

# Create a new MCP server
server = MocoPo::Server.new(
  name: "SimpleMCPServer",
  version: "1.0.0"
)

# By default, the HTTP transport is created automatically
# You can access it explicitly if needed
http_transport = server.transport_manager.try do |manager|
  manager.@transports.find { |t| t.is_a?(MocoPo::HttpTransport) }
end

# Register a sample tool
weather_tool = MocoPo::Tool.new(
  name: "get_weather",
  description: "Get current weather information for a location",
  input_schema: {
    "type"       => "object",
    "properties" => {
      "location" => {
        "type"        => "string",
        "description" => "City name or zip code",
      } of String => MocoPo::JsonValue,
    } of String => MocoPo::JsonValue,
    "required" => ["location"] of MocoPo::JsonValue,
  } of String => MocoPo::JsonValue
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
puts "Active transports: HTTP (default)"
server.start
