require "../../spec_helper"

module MocoPo
  describe StdioTransport do
    it "can be initialized" do
      transport = StdioTransport.new
      transport.should be_a(StdioTransport)
    end

    it "implements the Transport interface" do
      transport = StdioTransport.new
      transport.should be_a(Transport)
    end

    it "has a start method" do
      transport = StdioTransport.new
      transport.responds_to?(:start).should be_true
    end

    it "has a send method" do
      transport = StdioTransport.new
      transport.responds_to?(:send).should be_true
    end

    it "has a close method" do
      transport = StdioTransport.new
      transport.responds_to?(:close).should be_true
    end

    # Note: Testing actual stdio functionality would require
    # mocking STDIN and STDOUT, which is beyond the scope of these tests
  end
end
