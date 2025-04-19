require "../../spec_helper"

# Simple test for StdioTransport
describe MocoPo::StdioTransport do
  it "can be initialized" do
    transport = MocoPo::StdioTransport.new
    transport.should be_a(MocoPo::StdioTransport)
  end

  it "implements the Transport interface" do
    transport = MocoPo::StdioTransport.new
    transport.should be_a(MocoPo::Transport)
  end
end
