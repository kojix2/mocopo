require "../src/mocopo"
require "http/client"

# Create a new MCP server
server = MocoPo::Server.new("CompletionExample", "1.0.0")

# Register a prompt with arguments that support completion
server.register_prompt("code_review", "Review code in a specific language") do |prompt|
  # Add arguments that support completion
  prompt.add_argument("language", true, "Programming language")
  prompt.add_argument("format", false, "Output format")

  # Set the execution callback
  prompt.on_execute do |args|
    language = args.try &.["language"]?.try &.as_s || "unknown"
    format = args.try &.["format"]?.try &.as_s || "text"

    [
      MocoPo::PromptMessage.new("user", MocoPo::TextContent.new("Please review this #{language} code and provide feedback in #{format} format.")),
    ]
  end
end

# Register a resource with arguments that support completion
server.register_resource("file:///{path}", "File System", "Access files in the file system") do |resource|
  resource.on_read do |context|
    MocoPo::ResourceContent.text(
      uri: "file:///example.txt",
      text: "This is an example file.",
      mime_type: "text/plain"
    )
  end
end

# Start the server
puts "Starting completion example server on http://localhost:3000"
puts "The server has registered a prompt and a resource that support completion"
puts "Use a client to test completion by making requests to the server"
server.start
