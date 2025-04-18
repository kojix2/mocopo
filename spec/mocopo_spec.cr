require "./spec_helper"

describe MocoPo do
  it "has a version number" do
    MocoPo::VERSION.should_not be_nil
  end

  it "has a protocol version" do
    MocoPo::PROTOCOL_VERSION.should eq("2025-03-26")
  end
end

describe MocoPo::Server do
  it "can be initialized with a name and version" do
    server = create_test_server("TestServer", "1.0.0")
    server.should be_a(MocoPo::Server)
  end

  it "initializes a prompt manager" do
    server = create_test_server("TestServer", "1.0.0")
    server.prompt_manager.should be_a(MocoPo::PromptManager)
  end

  it "can register a prompt with a block" do
    server = create_test_server("TestServer", "1.0.0")
    prompt = server.register_prompt("greeting", "A greeting prompt") do |p|
      p.add_argument("name", true, "Name to greet")
      p.on_execute do |args|
        name = args.try &.["name"]?.try &.as_s || "World"
        [
          MocoPo::PromptMessage.new(
            "user",
            MocoPo::TextContent.new("Hello, #{name}!")
          ),
        ]
      end
    end

    prompt.should be_a(MocoPo::Prompt)
    prompt.name.should eq("greeting")
    prompt.description.should eq("A greeting prompt")
    prompt.arguments.size.should eq(1)
    prompt.arguments[0].name.should eq("name")

    server.prompt_manager.exists?("greeting").should be_true
    server.prompt_manager.get("greeting").should eq(prompt)
  end

  it "can register a prompt without a block" do
    server = create_test_server("TestServer", "1.0.0")
    prompt = server.register_prompt("simple", "A simple prompt")

    prompt.should be_a(MocoPo::Prompt)
    prompt.name.should eq("simple")
    prompt.description.should eq("A simple prompt")
    prompt.arguments.should be_empty

    server.prompt_manager.exists?("simple").should be_true
    server.prompt_manager.get("simple").should eq(prompt)
  end

  # More comprehensive tests would include:
  # - Testing JSON-RPC request handling
  # - Testing initialize request/response
  # - Testing error handling
  # - Testing tools, resources, and prompts functionality
  # These would typically use HTTP::Test or similar to mock requests
end
