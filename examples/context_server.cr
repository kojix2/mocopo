require "../src/mocopo"

# Create a new MCP server
server = MocoPo::Server.new(
  name: "ContextServer",
  version: "1.0.0"
)

# Register a tool that uses context for logging
server.register_tool("process_data", "Process data with progress reporting") do |tool|
  tool.argument_string("data", true, "Data to process")
  tool.on_execute do |args, context|
    data = args.try &.["data"]?.try &.as_s || ""

    # Log the start of processing
    context.try &.info("Starting to process data (length: #{data.size})")

    # Simulate processing with progress reporting
    words = data.split(/\s+/)
    total_words = words.size

    # Process each word (simulated)
    processed_words = [] of String
    words.each_with_index do |word, index|
      # Process the word (just uppercase in this example)
      processed_word = word.upcase
      processed_words << processed_word

      # Report progress every 5 words or at the end
      if (index + 1) % 5 == 0 || index == total_words - 1
        progress_percent = ((index + 1) / total_words.to_f * 100).to_i
        context.try &.report_progress(index + 1, total_words, "Processed #{index + 1}/#{total_words} words (#{progress_percent}%)")
      end
    end

    # Log completion
    context.try &.info("Finished processing #{total_words} words")

    # Return the result
    {
      "content" => [
        {
          "type" => "text",
          "text" => "Processed #{total_words} words: #{processed_words.join(" ")}",
        },
      ] of Hash(String, String),
      "isError" => "false",
    }
  end
end

# Register a resource that uses context
server.register_resource(
  uri: "file:///logs",
  name: "Logs",
  description: "System logs with context information",
  mime_type: "text/plain"
) do |resource|
  resource.on_read do |context|
    # Use the context information if available
    client_info = context ? "Request: #{context.request_id}, Client: #{context.client_id}" : "No context provided"

    # Log the access
    puts "Resource accessed: #{resource.uri} (#{client_info})"

    # Return the content
    MocoPo::ResourceContent.text(
      uri: resource.uri,
      text: "System logs\n==========\n\nAccessed at: #{Time.utc}\nContext: #{client_info}",
      mime_type: "text/plain"
    )
  end
end

# Register a tool that reads a resource using context
server.register_tool("read_logs", "Read system logs") do |tool|
  tool.on_execute do |args, context|
    # Use the context to read the logs resource
    contents = context.try &.read_resource("file:///logs") || [] of MocoPo::ResourceContent

    if contents.empty?
      {
        "content" => [
          {
            "type" => "text",
            "text" => "No logs available",
          },
        ] of Hash(String, String),
        "isError" => "false",
      }
    else
      log_content = contents[0].text || "No text content"
      {
        "content" => [
          {
            "type" => "text",
            "text" => "Retrieved logs:\n\n#{log_content}",
          },
        ] of Hash(String, String),
        "isError" => "false",
      }
    end
  end
end

# Start the server on port 3000
puts "Starting MCP server on http://localhost:3000/mcp"
puts "Press Ctrl+C to stop"
puts "Registered tools: #{server.tool_manager.list.map(&.name).join(", ")}"
puts "Registered resources: #{server.resource_manager.list.map(&.uri).join(", ")}"
server.start
