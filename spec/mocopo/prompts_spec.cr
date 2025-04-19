require "../spec_helper"

describe MocoPo::MessageContent do
  describe MocoPo::TextContent do
    it "can be initialized with text" do
      content = MocoPo::TextContent.new("Hello, World!")
      content.text.should eq("Hello, World!")
    end

    it "converts to a JSON-compatible hash" do
      content = MocoPo::TextContent.new("Hello, World!")
      json = content.to_json_object
      json["type"].should eq("text")
      json["text"].should eq("Hello, World!")
    end
  end

  describe MocoPo::ImageContent do
    it "can be initialized with data and mime type" do
      content = MocoPo::ImageContent.new("base64data", "image/png")
      content.data.should eq("base64data")
      content.mime_type.should eq("image/png")
    end

    it "converts to a JSON-compatible hash" do
      content = MocoPo::ImageContent.new("base64data", "image/png")
      json = content.to_json_object
      json["type"].should eq("image")
      json["data"].should eq("base64data")
      json["mimeType"].should eq("image/png")
    end
  end

  describe MocoPo::ResourceContentRef do
    it "can be initialized with URI and resource content" do
      resource_content = MocoPo::ResourceContent.text(
        uri: "file:///test",
        text: "Resource content",
        mime_type: "text/plain"
      )
      content = MocoPo::ResourceContentRef.new("file:///test", resource_content)
      content.uri.should eq("file:///test")
      content.resource.should eq(resource_content)
    end

    it "converts to a JSON-compatible hash" do
      resource_content = MocoPo::ResourceContent.text(
        uri: "file:///test",
        text: "Resource content",
        mime_type: "text/plain"
      )
      content = MocoPo::ResourceContentRef.new("file:///test", resource_content)
      json = content.to_json_object
      json["type"].should eq("resource")
      json["resource"].should be_a(Hash(String, String | Nil))
      json["resource"]["uri"].should eq("file:///test")
    end
  end
end

describe MocoPo::PromptMessage do
  it "can be initialized with role and content" do
    content = MocoPo::TextContent.new("Hello, World!")
    message = MocoPo::PromptMessage.new("user", content)
    message.role.should eq("user")
    message.content.should eq(content)
  end

  it "converts to a JSON-compatible hash" do
    content = MocoPo::TextContent.new("Hello, World!")
    message = MocoPo::PromptMessage.new("user", content)
    json = message.to_json_object
    json["role"].should eq("user")
    json["content"].should be_a(Hash(String, String | Hash(String, String | Nil)))
    json["content"].as(Hash)["type"].should eq("text")
    json["content"].as(Hash)["text"].should eq("Hello, World!")
  end
end

describe MocoPo::PromptArgument do
  it "can be initialized with name" do
    arg = MocoPo::PromptArgument.new("name")
    arg.name.should eq("name")
    arg.required.should be_false
    arg.description.should be_nil
  end

  it "can be initialized with optional parameters" do
    arg = MocoPo::PromptArgument.new("name", true, "A name argument")
    arg.name.should eq("name")
    arg.required.should be_true
    arg.description.should eq("A name argument")
  end

  it "converts to a JSON-compatible hash" do
    arg = MocoPo::PromptArgument.new("name", true, "A name argument")
    json = arg.to_json_object
    json["name"].should eq("name")
    json["required"].should be_true
    json["description"].should eq("A name argument")
  end

  it "omits nil description in JSON-compatible hash" do
    arg = MocoPo::PromptArgument.new("name", true)
    json = arg.to_json_object
    json["name"].should eq("name")
    json["required"].should be_true
    json.has_key?("description").should be_false
  end
end

describe MocoPo::Prompt do
  it "can be initialized with name and description" do
    prompt = MocoPo::Prompt.new("test_prompt", "A test prompt")
    prompt.name.should eq("test_prompt")
    prompt.description.should eq("A test prompt")
    prompt.arguments.should be_empty
  end

  it "can add arguments" do
    prompt = MocoPo::Prompt.new("test_prompt", "A test prompt")
    prompt.add_argument("name", true, "Name to greet")
    prompt.add_argument("age", false, "Age in years")

    prompt.arguments.size.should eq(2)
    prompt.arguments[0].name.should eq("name")
    prompt.arguments[0].required.should be_true
    prompt.arguments[0].description.should eq("Name to greet")
    prompt.arguments[1].name.should eq("age")
    prompt.arguments[1].required.should be_false
    prompt.arguments[1].description.should eq("Age in years")
  end

  it "can set and execute a callback" do
    prompt = MocoPo::Prompt.new("test_prompt", "A test prompt")
    prompt.on_execute do |args|
      name = "World"
      if args && args.has_key?("name")
        name_value = args["name"]
        name = name_value.is_a?(String) ? name_value : name_value.to_s
      end

      [
        MocoPo::PromptMessage.new(
          "user",
          MocoPo::TextContent.new("Hello, #{name}!")
        ),
      ]
    end

    # Execute with arguments
    args = {"name" => "Alice"} of String => MocoPo::JsonValue
    messages = prompt.execute(args)
    messages.size.should eq(1)
    messages[0].role.should eq("user")
    messages[0].content.should be_a(MocoPo::TextContent)
    messages[0].content.as(MocoPo::TextContent).text.should eq("Hello, Alice!")

    # Execute without arguments
    messages = prompt.execute(nil)
    messages.size.should eq(1)
    messages[0].role.should eq("user")
    messages[0].content.should be_a(MocoPo::TextContent)
    messages[0].content.as(MocoPo::TextContent).text.should eq("Hello, World!")
  end

  it "returns a default response when no callback is set" do
    prompt = MocoPo::Prompt.new("test_prompt", "A test prompt")
    messages = prompt.execute(nil)
    messages.size.should eq(1)
    messages[0].role.should eq("user")
    messages[0].content.should be_a(MocoPo::TextContent)
    messages[0].content.as(MocoPo::TextContent).text.should eq("Prompt execution not implemented for: test_prompt")
  end

  it "converts to a JSON-compatible hash" do
    prompt = MocoPo::Prompt.new("test_prompt", "A test prompt")
    prompt.add_argument("name", true, "Name to greet")

    json = prompt.to_json_object
    json["name"].should eq("test_prompt")
    json["description"].should eq("A test prompt")
    json["arguments"].should be_a(Array(Hash(String, String | Bool | Nil)))
    json["arguments"].as(Array).size.should eq(1)
    json["arguments"].as(Array)[0]["name"].should eq("name")
    json["arguments"].as(Array)[0]["required"].should be_true
    json["arguments"].as(Array)[0]["description"].should eq("Name to greet")
  end

  it "omits empty arguments in JSON-compatible hash" do
    prompt = MocoPo::Prompt.new("test_prompt", "A test prompt")
    json = prompt.to_json_object
    json["name"].should eq("test_prompt")
    json["description"].should eq("A test prompt")
    json.has_key?("arguments").should be_false
  end
end

describe MocoPo::PromptManager do
  it "can register and retrieve prompts" do
    manager = MocoPo::PromptManager.new

    prompt1 = MocoPo::Prompt.new("prompt1", "Prompt 1")
    prompt2 = MocoPo::Prompt.new("prompt2", "Prompt 2")

    manager.register(prompt1)
    manager.register(prompt2)

    manager.exists?("prompt1").should be_true
    manager.exists?("prompt2").should be_true
    manager.exists?("prompt3").should be_false

    manager.get("prompt1").should eq(prompt1)
    manager.get("prompt2").should eq(prompt2)
    manager.get("prompt3").should be_nil

    manager.list.size.should eq(2)
    manager.list.should contain(prompt1)
    manager.list.should contain(prompt2)
  end

  it "can remove prompts" do
    manager = MocoPo::PromptManager.new

    prompt = MocoPo::Prompt.new("prompt", "A prompt")

    manager.register(prompt)
    manager.exists?("prompt").should be_true

    manager.remove("prompt")
    manager.exists?("prompt").should be_false
  end
end
