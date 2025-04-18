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
    server = MocoPo::Server.new(name: "TestServer", version: "1.0.0")
    server.should be_a(MocoPo::Server)
  end

  # More comprehensive tests would include:
  # - Testing JSON-RPC request handling
  # - Testing initialize request/response
  # - Testing error handling
  # - Testing tools and resources functionality
  # These would typically use HTTP::Test or similar to mock requests
end
