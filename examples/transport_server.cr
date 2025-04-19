require "../src/mocopo"

# Create a new MCP server with all transports enabled
server = MocoPo::Server.new(
  name: "transport-server",
  version: "1.0.0",
  enabled_transports: [:http, :stdio, :sse]
)

# Register a simple tool
server.register_tool("echo", "Echo the input") do |tool|
  # Add input parameter
  tool.add_parameter("message", "Message to echo", "string", required: true)

  # Set handler
  tool.handler = ->(params : MocoPo::JsonObject) {
    message = params["message"]?.try &.as_s || "No message provided"
    {"message" => message}
  }
end

# Register a simple resource
server.register_resource("example://hello", "Hello World", "A simple hello world resource") do |resource|
  # Set content provider
  resource.content_provider = ->(uri : String, params : MocoPo::JsonObject?) {
    "Hello, World!"
  }
end

# Register a simple prompt
server.register_prompt("greeting", "A greeting prompt") do |prompt|
  # Set content
  prompt.content = "Hello, {{name}}!"

  # Add parameter
  prompt.add_parameter("name", "Name to greet", "string", required: true)
end

# Access the transports if needed
http_transport = server.transport_manager.try do |manager|
  manager.@transports.find { |t| t.is_a?(MocoPo::HttpTransport) }
end

stdio_transport = server.transport_manager.try do |manager|
  manager.@transports.find { |t| t.is_a?(MocoPo::StdioTransport) }
end

sse_transport = server.transport_manager.try do |manager|
  manager.@transports.find { |t| t.is_a?(MocoPo::SseTransport) }
end

puts "Starting MCP server with multiple transports:"
puts "- HTTP transport: POST to /mcp"
puts "- SSE transport: GET /sse for server-to-client, POST to /messages for client-to-server"
puts "- stdio transport: Reading from stdin, writing to stdout"
puts "Press Ctrl+C to stop"

# Start the server
server.start
