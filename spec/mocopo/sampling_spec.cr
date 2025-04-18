require "../spec_helper"

describe MocoPo::SamplingManager do
  it "registers default sampling methods" do
    manager = MocoPo::SamplingManager.new

    # Check that default sampling methods are registered
    manager.exists?("greedy").should be_true
    manager.exists?("temperature").should be_true
    manager.exists?("top_k").should be_true
    manager.exists?("top_p").should be_true
  end

  it "can get a sampling method by name" do
    manager = MocoPo::SamplingManager.new

    # Check that we can get an existing sampling method
    method = manager.get("greedy")
    method.should_not be_nil
    method.try &.name.should eq("greedy")

    # Check that non-existent sampling methods return nil
    manager.get("non_existent").should be_nil
  end

  it "can list all sampling methods" do
    manager = MocoPo::SamplingManager.new

    # Check that we can list all sampling methods
    methods = manager.list
    methods.size.should be >= 4
    methods.map(&.name).should contain("greedy")
    methods.map(&.name).should contain("temperature")
    methods.map(&.name).should contain("top_k")
    methods.map(&.name).should contain("top_p")
  end

  it "can create a message" do
    manager = MocoPo::SamplingManager.new
    server = MocoPo::Server.new("test", "1.0", false)
    context = MocoPo::Context.new("request-1", "client-1", server)

    # Create a request
    request = MocoPo::SamplingRequest.new(
      messages: [MocoPo::SamplingMessage.user_text("Hello, world!")],
      max_tokens: 100
    )

    # Create a message
    response = manager.create_message(request, context)
    response.should be_a(MocoPo::SamplingResponse)
    response.role.should eq("assistant")
    response.content.type.should eq("text")
    response.content.text.should_not be_nil
    response.model.should_not be_nil
    response.stop_reason.should_not be_nil
  end

  it "raises an error when creating a message with no messages" do
    manager = MocoPo::SamplingManager.new
    server = MocoPo::Server.new("test", "1.0", false)
    context = MocoPo::Context.new("request-1", "client-1", server)

    # Create a request with no messages
    request = MocoPo::SamplingRequest.new(
      messages: [] of MocoPo::SamplingMessage,
      max_tokens: 100
    )

    # Attempt to create a message
    expect_raises(MocoPo::SamplingError) do
      manager.create_message(request, context)
    end
  end
end

describe MocoPo::SamplingMessageContent do
  it "can create text content" do
    content = MocoPo::SamplingMessageContent.text("Hello, world!")
    content.type.should eq("text")
    content.text.should eq("Hello, world!")
    content.data.should be_nil
    content.mime_type.should be_nil
  end

  it "can create image content" do
    content = MocoPo::SamplingMessageContent.image("base64data", "image/jpeg")
    content.type.should eq("image")
    content.text.should be_nil
    content.data.should eq("base64data")
    content.mime_type.should eq("image/jpeg")
  end

  it "can create audio content" do
    content = MocoPo::SamplingMessageContent.audio("base64data", "audio/wav")
    content.type.should eq("audio")
    content.text.should be_nil
    content.data.should eq("base64data")
    content.mime_type.should eq("audio/wav")
  end

  it "can convert to and from JSON object" do
    content = MocoPo::SamplingMessageContent.text("Hello, world!")
    json = content.to_json_object
    json["type"].should eq("text")
    json["text"].should eq("Hello, world!")

    content2 = MocoPo::SamplingMessageContent.from_json_object(json)
    content2.type.should eq("text")
    content2.text.should eq("Hello, world!")
  end
end

describe MocoPo::SamplingMessage do
  it "can create user text message" do
    message = MocoPo::SamplingMessage.user_text("Hello, world!")
    message.role.should eq("user")
    message.content.type.should eq("text")
    message.content.text.should eq("Hello, world!")
  end

  it "can create assistant text message" do
    message = MocoPo::SamplingMessage.assistant_text("Hello, world!")
    message.role.should eq("assistant")
    message.content.type.should eq("text")
    message.content.text.should eq("Hello, world!")
  end

  it "can convert to and from JSON object" do
    message = MocoPo::SamplingMessage.user_text("Hello, world!")
    json = message.to_json_object
    json["role"].should eq("user")
    json["content"].should be_a(Hash(String, MocoPo::JsonValue))
    json["content"].as(Hash)["type"].should eq("text")
    json["content"].as(Hash)["text"].should eq("Hello, world!")

    message2 = MocoPo::SamplingMessage.from_json_object(json)
    message2.role.should eq("user")
    message2.content.type.should eq("text")
    message2.content.text.should eq("Hello, world!")
  end
end

describe MocoPo::ModelPreferences do
  it "can create model preferences" do
    hints = [MocoPo::ModelHint.new("claude-3-sonnet")]
    prefs = MocoPo::ModelPreferences.new(
      hints: hints,
      cost_priority: 0.3,
      speed_priority: 0.8,
      intelligence_priority: 0.5
    )

    prefs.hints.size.should eq(1)
    prefs.hints[0].name.should eq("claude-3-sonnet")
    prefs.cost_priority.should eq(0.3)
    prefs.speed_priority.should eq(0.8)
    prefs.intelligence_priority.should eq(0.5)
  end

  it "can convert to and from JSON object" do
    hints = [MocoPo::ModelHint.new("claude-3-sonnet")]
    prefs = MocoPo::ModelPreferences.new(
      hints: hints,
      cost_priority: 0.3,
      speed_priority: 0.8,
      intelligence_priority: 0.5
    )

    json = prefs.to_json_object
    json["hints"].should be_a(Array(MocoPo::JsonValue))
    json["hints"].as(Array).size.should eq(1)
    json["hints"].as(Array)[0].as(Hash)["name"].should eq("claude-3-sonnet")
    json["costPriority"].should eq(0.3)
    json["speedPriority"].should eq(0.8)
    json["intelligencePriority"].should eq(0.5)

    prefs2 = MocoPo::ModelPreferences.from_json_object(json)
    prefs2.hints.size.should eq(1)
    prefs2.hints[0].name.should eq("claude-3-sonnet")
    prefs2.cost_priority.should eq(0.3)
    prefs2.speed_priority.should eq(0.8)
    prefs2.intelligence_priority.should eq(0.5)
  end
end

describe MocoPo::SamplingRequest do
  it "can create a sampling request" do
    messages = [MocoPo::SamplingMessage.user_text("Hello, world!")]
    hints = [MocoPo::ModelHint.new("claude-3-sonnet")]
    model_preferences = MocoPo::ModelPreferences.new(
      hints: hints,
      cost_priority: 0.3,
      speed_priority: 0.8,
      intelligence_priority: 0.5
    )

    request = MocoPo::SamplingRequest.new(
      messages: messages,
      model_preferences: model_preferences,
      system_prompt: "You are a helpful assistant.",
      include_context: "thisServer",
      temperature: 0.7,
      max_tokens: 100
    )

    request.messages.size.should eq(1)
    request.messages[0].role.should eq("user")
    request.messages[0].content.text.should eq("Hello, world!")
    request.model_preferences.should_not be_nil
    request.model_preferences.try &.hints.size.should eq(1)
    request.system_prompt.should eq("You are a helpful assistant.")
    request.include_context.should eq("thisServer")
    request.temperature.should eq(0.7)
    request.max_tokens.should eq(100)
  end

  it "can convert to and from JSON object" do
    messages = [MocoPo::SamplingMessage.user_text("Hello, world!")]
    hints = [MocoPo::ModelHint.new("claude-3-sonnet")]
    model_preferences = MocoPo::ModelPreferences.new(
      hints: hints,
      cost_priority: 0.3,
      speed_priority: 0.8,
      intelligence_priority: 0.5
    )

    request = MocoPo::SamplingRequest.new(
      messages: messages,
      model_preferences: model_preferences,
      system_prompt: "You are a helpful assistant.",
      include_context: "thisServer",
      temperature: 0.7,
      max_tokens: 100
    )

    json = request.to_json_object
    json["messages"].should be_a(Array(MocoPo::JsonValue))
    json["messages"].as(Array).size.should eq(1)
    json["modelPreferences"].should be_a(Hash(String, MocoPo::JsonValue))
    json["systemPrompt"].should eq("You are a helpful assistant.")
    json["includeContext"].should eq("thisServer")
    json["temperature"].should eq(0.7)
    json["maxTokens"].should eq(100)

    request2 = MocoPo::SamplingRequest.from_json_object(json)
    request2.messages.size.should eq(1)
    request2.messages[0].role.should eq("user")
    request2.messages[0].content.text.should eq("Hello, world!")
    request2.model_preferences.should_not be_nil
    request2.system_prompt.should eq("You are a helpful assistant.")
    request2.include_context.should eq("thisServer")
    request2.temperature.should eq(0.7)
    request2.max_tokens.should eq(100)
  end
end

describe MocoPo::SamplingResponse do
  it "can create a sampling response" do
    content = MocoPo::SamplingMessageContent.text("Hello, world!")
    response = MocoPo::SamplingResponse.new(
      "assistant",
      content,
      "claude-3-sonnet-20240307",
      "endTurn"
    )

    response.role.should eq("assistant")
    response.content.type.should eq("text")
    response.content.text.should eq("Hello, world!")
    response.model.should eq("claude-3-sonnet-20240307")
    response.stop_reason.should eq("endTurn")
  end

  it "can convert to and from JSON object" do
    content = MocoPo::SamplingMessageContent.text("Hello, world!")
    response = MocoPo::SamplingResponse.new(
      "assistant",
      content,
      "claude-3-sonnet-20240307",
      "endTurn"
    )

    json = response.to_json_object
    json["role"].should eq("assistant")
    json["content"].should be_a(Hash(String, MocoPo::JsonValue))
    json["content"].as(Hash)["type"].should eq("text")
    json["content"].as(Hash)["text"].should eq("Hello, world!")
    json["model"].should eq("claude-3-sonnet-20240307")
    json["stopReason"].should eq("endTurn")

    response2 = MocoPo::SamplingResponse.from_json_object(json)
    response2.role.should eq("assistant")
    response2.content.type.should eq("text")
    response2.content.text.should eq("Hello, world!")
    response2.model.should eq("claude-3-sonnet-20240307")
    response2.stop_reason.should eq("endTurn")
  end
end

describe MocoPo::SamplingHandler do
  it "handles sampling/list requests" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::SamplingHandler.new(server)

    # Check that we can handle sampling/list requests
    response = handler.handle_list(1, nil)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil
  end

  it "handles sampling/sample requests" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::SamplingHandler.new(server)

    # Check that we can handle valid sampling/sample requests
    params = {
      "method" => "greedy",
      "text"   => "Hello, world!",
    } of String => MocoPo::JsonValue

    response = handler.handle_sample(1, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil
  end
end
