require "../src/mocopo"

# Create a new MCP server
server = MocoPo::Server.new("PaginationExample", "1.0.0")

# Register a large number of tools to demonstrate pagination
100.times do |i|
  server.register_tool("tool_#{i}", "Example tool #{i}") do |tool|
    tool.argument_string("input", true, "Input for tool #{i}")
    tool.on_execute do |args, context|
      input = args.try &.["input"]?.try &.as_s || ""
      {
        "content" => [
          {
            "type" => "text",
            "text" => "Tool #{i} executed with input: #{input}",
          },
        ] of Hash(String, String),
        "isError" => "false",
      }
    end
  end
end

# Register a large number of resources to demonstrate pagination
100.times do |i|
  server.register_resource("resource://example/#{i}", "Resource #{i}", "Example resource #{i}") do |resource|
    resource.on_read do |context|
      MocoPo::ResourceContent.text(
        uri: "resource://example/#{i}",
        text: "This is the content of resource #{i}",
        mime_type: "text/plain"
      )
    end
  end
end

# Register a large number of prompts to demonstrate pagination
100.times do |i|
  server.register_prompt("prompt_#{i}", "Example prompt #{i}") do |prompt|
    prompt.add_argument("input", true, "Input for prompt #{i}")
    prompt.on_execute do |args|
      input = args.try &.["input"]?.try &.as_s || ""
      [
        MocoPo::PromptMessage.new("user", MocoPo::TextContent.new("This is prompt #{i} with input: #{input}")),
      ]
    end
  end
end

# Start the server
puts "Starting pagination example server on http://localhost:3000"
puts "The server has registered 100 tools, 100 resources, and 100 prompts"
puts "Use a client to test pagination by making requests to the server"
server.start
