require "../src/mocopo"

# Create a new MCP server
server = MocoPo::Server.new(
  name: "SamplingMCPServer",
  version: "1.0.0"
)

# Register a sample tool
echo_tool = server.register_tool("echo", "Echo back the input") do |tool|
  tool
    .argument_string("text", true, "Text to echo")
    .on_execute do |args|
      text = args.try(&.["text"]?.try(&.as_s?)) || "No input"
      {
        "content" => [
          {
            "type" => "text",
            "text" => "Echo: #{text}",
          },
        ] of Hash(String, String),
        "isError" => "false",
      }
    end
end

# Register a sample resource
readme_resource = server.register_resource(
  uri: "file:///readme",
  name: "README",
  description: "Project README file",
  mime_type: "text/markdown"
) do |resource|
  resource.on_read do
    MocoPo::ResourceContent.text(
      uri: "file:///readme",
      text: "# Sampling MCP Server\n\nThis server demonstrates the sampling functionality.",
      mime_type: "text/markdown"
    )
  end
end

# Log a message when a sampling/createMessage request is received
puts "Starting MCP server with sampling support on http://localhost:3000/mcp"
puts "Press Ctrl+C to stop"
puts "Registered tools: #{server.tool_manager.list.map(&.name).join(", ")}"
puts "Registered resources: #{server.resource_manager.list.map(&.name).join(", ")}"
puts "Registered sampling methods: #{server.sampling_manager.list.map(&.name).join(", ")}"
puts ""
puts "Example sampling/createMessage request:"
puts "```json"
puts <<-JSON
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "sampling/createMessage",
  "params": {
    "messages": [
      {
        "role": "user",
        "content": {
          "type": "text",
          "text": "What is the capital of France?"
        }
      }
    ],
    "modelPreferences": {
      "hints": [
        {
          "name": "claude-3-sonnet"
        }
      ],
      "intelligencePriority": 0.8,
      "speedPriority": 0.5
    },
    "systemPrompt": "You are a helpful assistant.",
    "maxTokens": 100
  }
}
JSON
puts "```"

# Start the server on port 3000
server.start
