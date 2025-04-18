require "../src/mocopo"

# Create a new MCP server
server = MocoPo::Server.new("SecurityExample", "1.0.0")

# Register a tool with input validation
server.register_tool("echo", "Echo the input text") do |tool|
  tool.argument_string("text", true, "Text to echo")
  tool.on_execute do |args, context|
    text = args.try &.["text"]?.try &.as_s || ""
    {
      "content" => [
        {
          "type" => "text",
          "text" => "You said: #{text}",
        },
      ] of Hash(String, String),
      "isError" => "false",
    }
  end
end

# Register a tool with access control
server.register_tool("admin_tool", "Tool only for admins") do |tool|
  tool.argument_string("command", true, "Admin command")
  # Set allowed clients
  tool.allowed_clients = ["admin-client-1", "admin-client-2"]
  tool.on_execute do |args, context|
    command = args.try &.["command"]?.try &.as_s || ""
    {
      "content" => [
        {
          "type" => "text",
          "text" => "Executed admin command: #{command}",
        },
      ] of Hash(String, String),
      "isError" => "false",
    }
  end
end

# Register a tool that demonstrates output sanitization
server.register_tool("html_tool", "Tool that returns HTML") do |tool|
  tool.argument_string("html", false, "HTML to sanitize")
  tool.on_execute do |args, context|
    html = args.try &.["html"]?.try &.as_s || "<script>alert('XSS')</script>"
    {
      "content" => [
        {
          "type" => "text",
          "text" => "Sanitized HTML: #{html}",
        },
      ] of Hash(String, String),
      "isError" => "false",
    }
  end
end

# Setup test client for demonstrating rate limiting
spawn do
  # Wait for server to start
  sleep 2.seconds

  # Create a context for a regular client
  regular_context = MocoPo::Context.new("request-1", "regular-client", server)

  # Create a context for an admin client
  admin_context = MocoPo::Context.new("request-2", "admin-client-1", server)

  # Test input validation
  puts "\n=== Testing Input Validation ==="
  # Missing required argument
  result = server.tool_manager.execute_tool("echo", nil, regular_context)
  puts "Result: #{result["content"].as(Array)[0]["text"]}"
  puts "Error: #{result["isError"]}"

  # Valid input
  result = server.tool_manager.execute_tool("echo", {"text" => JSON::Any.new("Hello, world!")}, regular_context)
  puts "Result: #{result["content"].as(Array)[0]["text"]}"
  puts "Error: #{result["isError"]}"

  # Test access control
  puts "\n=== Testing Access Control ==="
  # Regular client trying to access admin tool
  result = server.tool_manager.execute_tool("admin_tool", {"command" => JSON::Any.new("list users")}, regular_context)
  puts "Result: #{result["content"].as(Array)[0]["text"]}"
  puts "Error: #{result["isError"]}"

  # Admin client accessing admin tool
  result = server.tool_manager.execute_tool("admin_tool", {"command" => JSON::Any.new("list users")}, admin_context)
  puts "Result: #{result["content"].as(Array)[0]["text"]}"
  puts "Error: #{result["isError"]}"

  # Test output sanitization
  puts "\n=== Testing Output Sanitization ==="
  result = server.tool_manager.execute_tool("html_tool", {"html" => JSON::Any.new("<script>alert('XSS')</script>")}, regular_context)
  puts "Result: #{result["content"].as(Array)[0]["text"]}"

  # Test rate limiting
  puts "\n=== Testing Rate Limiting ==="
  6.times do |i|
    result = server.tool_manager.execute_tool("echo", {"text" => JSON::Any.new("Call #{i + 1}")}, regular_context)
    puts "Call #{i + 1} - Result: #{result["content"].as(Array)[0]["text"]}"
    puts "Call #{i + 1} - Error: #{result["isError"]}"
  end
end

# Start the server
puts "Starting security example server on http://localhost:3000"
puts "Watch the console for security feature demonstrations"
server.start
