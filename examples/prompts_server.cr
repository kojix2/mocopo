require "../src/mocopo"

# Create a new MCP server
server = MocoPo::Server.new(
  name: "PromptsServer",
  version: "1.0.0"
)

# Register a simple greeting prompt
server.register_prompt("greeting", "A simple greeting prompt") do |prompt|
  prompt.add_argument("name", true, "Name to greet")
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

# Register a code review prompt
server.register_prompt("code_review", "Ask for a code review") do |prompt|
  prompt.add_argument("code", true, "Code to review")
  prompt.add_argument("language", false, "Programming language")
  prompt.on_execute do |args|
    code = args.try &.["code"]?.try &.as_s || "# No code provided"
    language = args.try &.["language"]?.try &.as_s || "unknown"

    [
      MocoPo::PromptMessage.new(
        "user",
        MocoPo::TextContent.new("Please review this #{language} code:\n\n```#{language}\n#{code}\n```")
      ),
    ]
  end
end

# Register a multi-message conversation prompt
server.register_prompt("interview", "Technical interview simulation") do |prompt|
  prompt.add_argument("position", true, "Job position")
  prompt.add_argument("experience_level", false, "Experience level (junior, mid, senior)")
  prompt.on_execute do |args|
    position = args.try &.["position"]?.try &.as_s || "Software Engineer"
    experience = args.try &.["experience_level"]?.try &.as_s || "mid"

    [
      MocoPo::PromptMessage.new(
        "user",
        MocoPo::TextContent.new("I'm interviewing for a #{position} position at the #{experience} level. Can you ask me some technical questions?")
      ),
      MocoPo::PromptMessage.new(
        "assistant",
        MocoPo::TextContent.new("I'd be happy to simulate a technical interview for a #{experience}-level #{position} position. Let's start with a question:\n\nCan you explain the difference between synchronous and asynchronous programming, and provide an example of when you would use each?")
      ),
    ]
  end
end

# Start the server on port 3000
puts "Starting MCP server on http://localhost:3000/mcp"
puts "Press Ctrl+C to stop"
puts "Registered prompts: #{server.prompt_manager.list.map(&.name).join(", ")}"
server.start
