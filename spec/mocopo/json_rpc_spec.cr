require "../spec_helper"

describe MocoPo::JsonRpcMessage do
  # Abstract class, so we test through concrete implementations
end

describe MocoPo::JsonRpcSuccessResponse do
  it "can be initialized with a result" do
    response = MocoPo::JsonRpcSuccessResponse.new({"key" => "value"} of String => MocoPo::JsonValue, 1)
    response.jsonrpc.should eq("2.0")
    response.id.should eq(1)
    response.result.as(Hash)["key"].should eq("value")
  end

  it "converts to a JSON-compatible Hash" do
    response = MocoPo::JsonRpcSuccessResponse.new({"key" => "value"} of String => MocoPo::JsonValue, 1)
    json_obj = response.to_json_object
    json_obj["jsonrpc"].should eq("2.0")
    json_obj["id"].should eq(1)
    json_obj["result"].as(Hash)["key"].should eq("value")
  end
end

describe MocoPo::JsonRpcError do
  it "can be initialized with code and message" do
    error = MocoPo::JsonRpcError.new(-32600, "Invalid Request")
    error.code.should eq(-32600)
    error.message.should eq("Invalid Request")
    error.data.should be_nil
  end

  it "can be initialized with additional data" do
    error = MocoPo::JsonRpcError.new(-32600, "Invalid Request", {"detail" => "Missing field"} of String => MocoPo::JsonValue)
    error.code.should eq(-32600)
    error.message.should eq("Invalid Request")
    error.data.should_not be_nil
  end

  it "converts to a JSON-compatible Hash" do
    error = MocoPo::JsonRpcError.new(-32600, "Invalid Request")
    json_obj = error.to_json_object
    json_obj["code"].should eq(-32600)
    json_obj["message"].should eq("Invalid Request")
    json_obj.has_key?("data").should be_false
  end

  it "includes data in JSON-compatible Hash if present" do
    error = MocoPo::JsonRpcError.new(-32600, "Invalid Request", {"detail" => "Missing field"} of String => MocoPo::JsonValue)
    json_obj = error.to_json_object
    json_obj["data"].should_not be_nil
  end
end

describe MocoPo::JsonRpcErrorResponse do
  it "can be initialized with an error" do
    error = MocoPo::JsonRpcError.new(-32600, "Invalid Request")
    response = MocoPo::JsonRpcErrorResponse.new(error, 1)
    response.jsonrpc.should eq("2.0")
    response.id.should eq(1)
    response.error.should eq(error)
  end

  it "converts to a JSON-compatible Hash" do
    error = MocoPo::JsonRpcError.new(-32600, "Invalid Request")
    response = MocoPo::JsonRpcErrorResponse.new(error, 1)
    json_obj = response.to_json_object
    json_obj["jsonrpc"].should eq("2.0")
    json_obj["id"].should eq(1)
    json_obj["error"].as(Hash)["code"].should eq(-32600)
    json_obj["error"].as(Hash)["message"].should eq("Invalid Request")
  end
end

describe MocoPo::JsonRpcNotification do
  it "can be initialized with a method" do
    notification = MocoPo::JsonRpcNotification.new("update")
    notification.jsonrpc.should eq("2.0")
    notification.method.should eq("update")
    notification.params.should be_nil
  end

  it "can be initialized with method and params" do
    params = {"key" => "value"} of String => MocoPo::JsonValue
    notification = MocoPo::JsonRpcNotification.new("update", params)
    notification.jsonrpc.should eq("2.0")
    notification.method.should eq("update")
    notification.params.should eq(params)
  end

  it "converts to a JSON-compatible Hash" do
    params = {"key" => "value"} of String => MocoPo::JsonValue
    notification = MocoPo::JsonRpcNotification.new("update", params)
    json_obj = notification.to_json_object
    json_obj["jsonrpc"].should eq("2.0")
    json_obj["method"].should eq("update")
    json_obj["params"].as(Hash)["key"].should eq("value")
  end

  it "omits params in JSON-compatible Hash if nil" do
    notification = MocoPo::JsonRpcNotification.new("update")
    json_obj = notification.to_json_object
    json_obj.has_key?("params").should be_false
  end
end

describe MocoPo::JsonRpcRequest do
  it "can be initialized with a method" do
    request = MocoPo::JsonRpcRequest.new("method")
    request.jsonrpc.should eq("2.0")
    request.method.should eq("method")
    request.id.should be_nil
    request.params.should be_nil
  end

  it "can be initialized with method, id, and params" do
    params = {"key" => "value"} of String => MocoPo::JsonValue
    request = MocoPo::JsonRpcRequest.new("method", 1, params)
    request.jsonrpc.should eq("2.0")
    request.method.should eq("method")
    request.id.should eq(1)
    request.params.should eq(params)
  end

  it "converts to a JSON-compatible Hash" do
    params = {"key" => "value"} of String => MocoPo::JsonValue
    request = MocoPo::JsonRpcRequest.new("method", 1, params)
    json_obj = request.to_json_object
    json_obj["jsonrpc"].should eq("2.0")
    json_obj["method"].should eq("method")
    json_obj["id"].should eq(1)
    json_obj["params"].as(Hash)["key"].should eq("value")
  end

  it "omits params in JSON-compatible Hash if nil" do
    request = MocoPo::JsonRpcRequest.new("method", 1)
    json_obj = request.to_json_object
    json_obj.has_key?("params").should be_false
  end
end
