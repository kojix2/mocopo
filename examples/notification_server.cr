require "../src/mocopo"

# Create a new MCP server
server = MocoPo::Server.new("NotificationExample", "1.0.0")

# Create and register multiple transports to demonstrate notifications across different transports
http_transport = server.create_http_transport # Default HTTP transport
sse_transport = server.create_sse_transport   # Server-Sent Events transport for real-time notifications

puts "Configured transports for notifications:"
puts "- HTTP: POST to /mcp (limited notification support)"
puts "- SSE: GET /sse for server-to-client streaming notifications"

# Register some initial tools
server.register_tool("hello_world", "A simple hello world tool") do |tool|
  tool.argument_string("name", false, "Name to greet")
  tool.on_execute do |args, context|
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
end

# Register some initial resources
server.register_resource("file:///example.txt", "Example Text File", "A simple text file example", "text/plain") do |resource|
  resource.on_read do |context|
    MocoPo::ResourceContent.text(
      uri: resource.uri,
      text: "This is an example text file.",
      mime_type: "text/plain"
    )
  end
end

# Register some initial prompts
server.register_prompt("greeting", "A simple greeting prompt") do |prompt|
  prompt.add_argument("name", false, "Name to greet")
  prompt.on_execute do |args|
    name = args.try &.["name"]?.try &.as_s || "World"
    [
      MocoPo::PromptMessage.new(
        "user",
        MocoPo::TextContent.new("Hello, #{name}!")
      ),
    ]
  end
end

# Setup dynamic registration example
spawn do
  # Wait for server to start
  sleep 2.seconds

  puts "\n=== Adding new tool ==="
  server.register_tool("calculate", "A simple calculator tool") do |tool|
    tool.argument_string("expression", true, "Expression to calculate")
    tool.on_execute do |args, context|
      expression = args.try &.["expression"]?.try &.as_s || "0"
      result = "Error: Invalid expression"

      begin
        # This is just a simple example with a very basic calculator
        if expression =~ /^[0-9+\-*\/\s.()]+$/
          # Simple calculator that only handles basic operations
          # In a real app, you'd use a proper expression evaluator
          if expression.includes?("+")
            parts = expression.split("+")
            result = (parts[0].to_f + parts[1].to_f).to_s
          elsif expression.includes?("-")
            parts = expression.split("-")
            result = (parts[0].to_f - parts[1].to_f).to_s
          elsif expression.includes?("*")
            parts = expression.split("*")
            result = (parts[0].to_f * parts[1].to_f).to_s
          elsif expression.includes?("/")
            parts = expression.split("/")
            result = (parts[0].to_f / parts[1].to_f).to_s
          else
            result = expression # Just return the number itself
          end
        end
      rescue ex
        result = "Error: #{ex.message}"
      end

      {
        "content" => [
          {
            "type" => "text",
            "text" => "Result: #{result}",
          },
        ] of Hash(String, String),
        "isError" => "false",
      }
    end
  end

  sleep 2.seconds

  puts "\n=== Adding new resource ==="
  server.register_resource("file:///example2.txt", "Second Example File", "Another text file example", "text/plain") do |resource|
    resource.on_read do |context|
      MocoPo::ResourceContent.text(
        uri: resource.uri,
        text: "This is another example text file.",
        mime_type: "text/plain"
      )
    end
  end

  sleep 2.seconds

  puts "\n=== Adding new prompt ==="
  server.register_prompt("farewell", "A simple farewell prompt") do |prompt|
    prompt.add_argument("name", false, "Name to bid farewell")
    prompt.on_execute do |args|
      name = args.try &.["name"]?.try &.as_s || "World"
      [
        MocoPo::PromptMessage.new(
          "user",
          MocoPo::TextContent.new("Goodbye, #{name}!")
        ),
      ]
    end
  end

  sleep 2.seconds

  puts "\n=== Removing a tool ==="
  server.tool_manager.remove("hello_world")

  sleep 2.seconds

  puts "\n=== Removing a resource ==="
  server.resource_manager.remove("file:///example.txt")

  sleep 2.seconds

  puts "\n=== Removing a prompt ==="
  server.prompt_manager.remove("greeting")

  sleep 2.seconds

  puts "\n=== Updating a resource ==="
  server.resource_manager.notify_resource_updated("file:///example2.txt")
end

# Start the server
puts "Starting notification example server on http://localhost:3000"
puts "Watch the console for notification events"
puts "For SSE notifications, connect to http://localhost:3000/sse"
puts "Notifications will be sent through all configured transports"
server.start
