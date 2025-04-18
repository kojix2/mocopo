require "../src/mocopo"

# Create a new MCP server
server = MocoPo::Server.new(
  name: "RootsMCPServer",
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
      text: "# Roots MCP Server\n\nThis server demonstrates the roots functionality.",
      mime_type: "text/markdown"
    )
  end
end

# Register roots
current_dir = Dir.current
server.register_root(
  "current",
  "Current Directory",
  "The current working directory",
  current_dir,
  true # read-only
)

# Create a writable temp directory
temp_dir = File.join(Dir.tempdir, "mocopo_roots_example")
Dir.mkdir_p(temp_dir) unless Dir.exists?(temp_dir)

# Create a sample file in the temp directory
File.write(File.join(temp_dir, "sample.txt"), "This is a sample file in the temp directory.")

# Register the temp directory as a writable root
server.register_root(
  "temp",
  "Temp Directory",
  "A writable temporary directory",
  temp_dir,
  false # writable
)

# Log a message when the server starts
puts "Starting MCP server with roots support on http://localhost:3000/mcp"
puts "Press Ctrl+C to stop"
puts "Registered tools: #{server.tool_manager.list.map(&.name).join(", ")}"
puts "Registered resources: #{server.resource_manager.list.map(&.name).join(", ")}"
puts "Registered roots: #{server.root_manager.list.map(&.id).join(", ")}"
puts ""
puts "Example roots/list request:"
puts "```json"
puts <<-JSON
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "roots/list"
}
JSON
puts "```"
puts ""
puts "Example roots/listDirectory request:"
puts "```json"
puts <<-JSON
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "roots/listDirectory",
  "params": {
    "rootId": "current",
    "path": "/"
  }
}
JSON
puts "```"
puts ""
puts "Example roots/readFile request:"
puts "```json"
puts <<-JSON
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "roots/readFile",
  "params": {
    "rootId": "temp",
    "path": "/sample.txt"
  }
}
JSON
puts "```"
puts ""
puts "Example roots/writeFile request (temp root is writable):"
puts "```json"
puts <<-JSON
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "roots/writeFile",
  "params": {
    "rootId": "temp",
    "path": "/new_file.txt",
    "content": "This is a new file created via the roots API."
  }
}
JSON
puts "```"

# Start the server on port 3000
server.start
