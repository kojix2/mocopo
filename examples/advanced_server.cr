require "../src/mocopo"

# Create a new MCP server with all transports enabled
server = MocoPo::Server.new(
  name: "AdvancedMCPServer",
  version: "1.0.0",
  enabled_transports: [:http, :sse, :stdio]
)

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

# Log transport information to STDERR
STDERR.puts "Configured multiple transports:"
STDERR.puts "- HTTP: POST to /mcp"
STDERR.puts "- SSE: GET /sse for server-to-client, POST to /messages for client-to-server"
STDERR.puts "- stdio: Reading from stdin, writing to stdout"

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
          "text" => "Hello, #{name}!",
        },
      ] of Hash(String, String),
      "isError" => "false",
    }
  end

# Register a tool with nested arguments
full_name_tool = server.register_tool("greet_full_name", "Greet someone by their full name")
full_name_tool
  .argument_object("person", true, "Person to greet") do |obj|
    obj.string("first_name", false, "First name")
    obj.string("last_name", false, "Last name")
  end
  .on_execute do |args|
    first_name = args.try &.["person"]?.try &.["first_name"]?.try &.as_s || "John"
    last_name = args.try &.["person"]?.try &.["last_name"]?.try &.as_s || "Doe"
    {
      "content" => [
        {
          "type" => "text",
          "text" => "Hello, #{first_name} #{last_name}!",
        },
      ] of Hash(String, String),
      "isError" => "false",
    }
  end

# Register a tool with array arguments
group_greeting_tool = server.register_tool("group_greeting", "Greet multiple people at once")
group_greeting_tool
  .argument_array("people", "string", true, "People to greet")
  .on_execute do |args|
    people = [] of String
    if args && args["people"]?
      args["people"].as_a.each do |person|
        people << person.as_s
      end
    end

    greeting = people.empty? ? "Hello, everyone!" : "Hello, #{people.join(", ")}!"

    {
      "content" => [
        {
          "type" => "text",
          "text" => greeting,
        },
      ] of Hash(String, String),
      "isError" => "false",
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
    text: "# Advanced MCP Server\n\nThis is a sample README file for the advanced MCP server example.",
    mime_type: "text/markdown"
  )
end

# Start the server on port 3000
# Note: Server will log information to STDERR automatically

# Send a notification to all connected clients when the server starts
if notification_manager = server.notification_manager
  notification_manager.send_notification("server/started", {"message" => "Server started successfully"})
end

server.start
