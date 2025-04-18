require "../spec_helper"

describe MocoPo::CancellationToken do
  it "can be created with valid parameters" do
    token = MocoPo::CancellationToken.new("test-token")
    token.id.should eq("test-token")
    token.cancelled.should be_false
    token.reason.should be_nil
  end

  it "can be cancelled" do
    token = MocoPo::CancellationToken.new("test-token")
    token.cancel
    token.cancelled.should be_true
    token.reason.should be_nil
  end

  it "can be cancelled with a reason" do
    token = MocoPo::CancellationToken.new("test-token")
    token.cancel("User requested cancellation")
    token.cancelled.should be_true
    token.reason.should eq("User requested cancellation")
  end

  it "can check if it is cancelled" do
    token = MocoPo::CancellationToken.new("test-token")
    token.cancelled?.should be_false
    token.cancel
    token.cancelled?.should be_true
  end

  it "can convert to JSON-compatible Hash" do
    token = MocoPo::CancellationToken.new("test-token")
    json = token.to_json_object
    json["id"].should eq("test-token")
    json["cancelled"].should be_false
    json.has_key?("reason").should be_false

    token.cancel("User requested cancellation")
    json = token.to_json_object
    json["id"].should eq("test-token")
    json["cancelled"].should be_true
    json["reason"].should eq("User requested cancellation")
  end
end

describe MocoPo::CancellationManager do
  it "can create a token with a specified ID" do
    manager = MocoPo::CancellationManager.new
    token = manager.create_token("test-token")
    token.id.should eq("test-token")
    token.cancelled.should be_false
  end

  it "can create a token with a generated ID" do
    manager = MocoPo::CancellationManager.new
    token = manager.create_token
    token.id.should_not be_empty
    token.cancelled.should be_false
  end

  it "can get a token by ID" do
    manager = MocoPo::CancellationManager.new
    token = manager.create_token("test-token")
    manager.get_token("test-token").should eq(token)
    manager.get_token("non-existent").should be_nil
  end

  it "can cancel a token by ID" do
    manager = MocoPo::CancellationManager.new
    manager.create_token("test-token")
    manager.cancel_token("test-token").should be_true
    manager.get_token("test-token").not_nil!.cancelled.should be_true
  end

  it "can cancel a token with a reason" do
    manager = MocoPo::CancellationManager.new
    manager.create_token("test-token")
    manager.cancel_token("test-token", "User requested cancellation").should be_true
    token = manager.get_token("test-token").not_nil!
    token.cancelled.should be_true
    token.reason.should eq("User requested cancellation")
  end

  it "returns false when cancelling a non-existent token" do
    manager = MocoPo::CancellationManager.new
    manager.cancel_token("non-existent").should be_false
  end

  it "can check if a token is cancelled" do
    manager = MocoPo::CancellationManager.new
    manager.create_token("test-token")
    manager.is_cancelled?("test-token").should be_false
    manager.cancel_token("test-token")
    manager.is_cancelled?("test-token").should be_true
  end

  it "returns false when checking if a non-existent token is cancelled" do
    manager = MocoPo::CancellationManager.new
    manager.is_cancelled?("non-existent").should be_false
  end

  it "can list all tokens" do
    manager = MocoPo::CancellationManager.new
    token1 = manager.create_token("token1")
    token2 = manager.create_token("token2")
    tokens = manager.list
    tokens.size.should eq(2)
    tokens.should contain(token1)
    tokens.should contain(token2)
  end

  it "can remove a token" do
    manager = MocoPo::CancellationManager.new
    manager.create_token("test-token")
    manager.remove_token("test-token").should be_true
    manager.get_token("test-token").should be_nil
  end

  it "returns false when removing a non-existent token" do
    manager = MocoPo::CancellationManager.new
    manager.remove_token("non-existent").should be_false
  end

  it "can clear all tokens" do
    manager = MocoPo::CancellationManager.new
    manager.create_token("token1")
    manager.create_token("token2")
    manager.list.size.should eq(2)
    manager.clear
    manager.list.should be_empty
  end
end

describe MocoPo::Server do
  it "initializes a cancellation manager" do
    server = MocoPo::Server.new("test", "1.0", false)
    server.cancellation_manager.should be_a(MocoPo::CancellationManager)
  end

  it "can create a cancellation token" do
    server = MocoPo::Server.new("test", "1.0", false)
    token = server.create_cancellation_token("test-token")
    token.id.should eq("test-token")
    token.cancelled.should be_false
  end

  it "can cancel a token" do
    server = MocoPo::Server.new("test", "1.0", false)
    server.create_cancellation_token("test-token")
    server.cancel_token("test-token").should be_true
    server.is_cancelled?("test-token").should be_true
  end

  it "can check if a token is cancelled" do
    server = MocoPo::Server.new("test", "1.0", false)
    server.create_cancellation_token("test-token")
    server.is_cancelled?("test-token").should be_false
    server.cancel_token("test-token")
    server.is_cancelled?("test-token").should be_true
  end
end

describe MocoPo::CancellationHandler do
  it "handles cancellation/create requests" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::CancellationHandler.new(server)

    # Test with no parameters
    response = handler.handle_create(1, nil)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil
    result = response["result"]
    result.should be_a(Hash(String, MocoPo::JsonValue))
    result.as(Hash)["id"]?.should_not be_nil
    result.as(Hash)["cancelled"].should be_false

    # Test with ID parameter
    params = {
      "id" => "test-token",
    } of String => MocoPo::JsonValue

    response = handler.handle_create(2, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil
    result = response["result"]
    result.should be_a(Hash(String, MocoPo::JsonValue))
    result.as(Hash)["id"].should eq("test-token")
    result.as(Hash)["cancelled"].should be_false
  end

  it "handles cancellation/cancel requests" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::CancellationHandler.new(server)
    server.create_cancellation_token("test-token")

    params = {
      "id" => "test-token",
    } of String => MocoPo::JsonValue

    response = handler.handle_cancel(1, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil
    result = response["result"]
    result.should be_a(Hash(String, MocoPo::JsonValue))
    result.as(Hash)["success"].should be_true

    # Test with reason
    server.create_cancellation_token("test-token-2")
    params = {
      "id"     => "test-token-2",
      "reason" => "User requested cancellation",
    } of String => MocoPo::JsonValue

    response = handler.handle_cancel(2, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil
    result = response["result"]
    result.should be_a(Hash(String, MocoPo::JsonValue))
    result.as(Hash)["success"].should be_true

    # Test with non-existent token
    params = {
      "id" => "non-existent",
    } of String => MocoPo::JsonValue

    response = handler.handle_cancel(3, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["error"]?.should_not be_nil
    error = response["error"]
    error.should be_a(Hash(String, MocoPo::JsonValue))
    error.as(Hash)["code"].should eq(-32602)
  end

  it "handles cancellation/status requests" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::CancellationHandler.new(server)
    server.create_cancellation_token("test-token")

    params = {
      "id" => "test-token",
    } of String => MocoPo::JsonValue

    response = handler.handle_status(1, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil
    result = response["result"]
    result.should be_a(Hash(String, MocoPo::JsonValue))
    result.as(Hash)["id"].should eq("test-token")
    result.as(Hash)["cancelled"].should be_false

    # Test with cancelled token
    server.cancel_token("test-token", "User requested cancellation")
    response = handler.handle_status(2, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil
    result = response["result"]
    result.should be_a(Hash(String, MocoPo::JsonValue))
    result.as(Hash)["id"].should eq("test-token")
    result.as(Hash)["cancelled"].should be_true
    result.as(Hash)["reason"].should eq("User requested cancellation")

    # Test with non-existent token
    params = {
      "id" => "non-existent",
    } of String => MocoPo::JsonValue

    response = handler.handle_status(3, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["error"]?.should_not be_nil
    error = response["error"]
    error.should be_a(Hash(String, MocoPo::JsonValue))
    error.as(Hash)["code"].should eq(-32602)
  end

  it "handles cancellation/list requests" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::CancellationHandler.new(server)
    server.create_cancellation_token("token1")
    server.create_cancellation_token("token2")

    response = handler.handle_list(1, nil)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil
    result = response["result"]
    result.should be_a(Hash(String, MocoPo::JsonValue))
    result.as(Hash)["tokens"]?.should_not be_nil
    tokens = result.as(Hash)["tokens"]
    tokens.should be_a(Array(MocoPo::JsonValue))
    tokens.as(Array).size.should eq(2)
    token_ids = tokens.as(Array).map { |t| t.as(Hash)["id"].as(String) }
    token_ids.should contain("token1")
    token_ids.should contain("token2")
  end

  it "handles unknown methods" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::CancellationHandler.new(server)

    response = handler.handle(1, "unknown", nil)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["error"]?.should_not be_nil
    error = response["error"]
    error.should be_a(Hash(String, MocoPo::JsonValue))
    error.as(Hash)["code"].should eq(-32601)
  end
end
