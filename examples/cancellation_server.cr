require "../src/mocopo"

# Create a new MCP server
server = MocoPo::Server.new(
  name: "CancellationMCPServer",
  version: "1.0.0"
)

# Register a sample tool that simulates a long-running operation
long_running_tool = server.register_tool("longRunning", "A tool that simulates a long-running operation") do |tool|
  tool
    .argument_number("duration", true, "Duration in seconds")
    .argument_string("token", false, "Cancellation token ID")
    .on_execute do |args|
      # Get duration
      duration = args.try(&.["duration"]?.try(&.as_f?)) || 10.0

      # Get cancellation token ID
      token_id = args.try(&.["token"]?.try(&.as_s?))

      # Create a cancellation token if not provided
      if token_id.nil?
        token = server.create_cancellation_token
        token_id = token.id
      end

      # Simulate a long-running operation
      start_time = Time.monotonic
      result = "Operation completed successfully"

      # Check for cancellation every 0.1 seconds
      while Time.monotonic - start_time < Time::Span.new(seconds: duration.to_i, nanoseconds: (duration % 1 * 1_000_000_000).to_i)
        # Check if the operation has been cancelled
        if server.is_cancelled?(token_id)
          # Get the cancellation reason
          token = server.cancellation_manager.get_token(token_id)
          reason = token.try(&.reason) || "Unknown reason"

          # Return error
          next {
            "content" => [
              {
                "type" => "text",
                "text" => "Operation cancelled: #{reason}",
              },
            ] of Hash(String, String),
            "isError" => "true",
            "tokenId" => token_id,
          }
        end

        # Sleep for a short time
        sleep 0.1
      end

      # Return success
      next {
        "content" => [
          {
            "type" => "text",
            "text" => result,
          },
        ] of Hash(String, String),
        "isError" => "false",
        "tokenId" => token_id,
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
      text: "# Cancellation MCP Server\n\nThis server demonstrates the cancellation functionality.",
      mime_type: "text/markdown"
    )
  end
end

# Log a message when the server starts
puts "Starting MCP server with cancellation support on http://localhost:3000/mcp"
puts "Press Ctrl+C to stop"
puts "Registered tools: #{server.tool_manager.list.map(&.name).join(", ")}"
puts "Registered resources: #{server.resource_manager.list.map(&.name).join(", ")}"
puts ""
puts "Example cancellation/create request:"
puts "```json"
puts <<-JSON
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "cancellation/create",
  "params": {
    "id": "my-token"
  }
}
JSON
puts "```"
puts ""
puts "Example cancellation/cancel request:"
puts "```json"
puts <<-JSON
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "cancellation/cancel",
  "params": {
    "id": "my-token",
    "reason": "User requested cancellation"
  }
}
JSON
puts "```"
puts ""
puts "Example cancellation/status request:"
puts "```json"
puts <<-JSON
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "cancellation/status",
  "params": {
    "id": "my-token"
  }
}
JSON
puts "```"
puts ""
puts "Example cancellation/list request:"
puts "```json"
puts <<-JSON
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "cancellation/list"
}
JSON
puts "```"
puts ""
puts "Example tools/call request with longRunning tool:"
puts "```json"
puts <<-JSON
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "tools/call",
  "params": {
    "name": "longRunning",
    "arguments": {
      "duration": 10,
      "token": "my-token"
    }
  }
}
JSON
puts "```"

# Start the server on port 3000
server.start
