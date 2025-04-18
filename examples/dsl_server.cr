require "../src/mocopo"

# Create a new MCP server
server = MocoPo::Server.new(
  name: "DSLStyleServer",
  version: "1.0.0"
)

# Register tools using the DSL-style API
server.register_tool("get_weather", "Get current weather information for a location") { }
server.register_tool("search_web", "Search the web for information") { }
server.register_tool("translate", "Translate text between languages") { }

# Register resources using the DSL-style API
server.register_resource(
  uri: "file:///readme",
  name: "README",
  description: "Project README file",
  mime_type: "text/markdown"
)

server.register_resource(
  uri: "file:///config",
  name: "Configuration",
  description: "Project configuration file",
  mime_type: "application/json"
)

# Start the server on port 3000
puts "Starting MCP server on http://localhost:3000/mcp"
puts "Press Ctrl+C to stop"
puts "Registered tools: #{server.tool_manager.list.map(&.name).join(", ")}"
puts "Registered resources: #{server.resource_manager.list.map(&.name).join(", ")}"
server.start
