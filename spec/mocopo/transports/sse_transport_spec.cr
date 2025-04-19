require "../../spec_helper"

module MocoPo
  describe SseTransport do
    it "can be initialized with a server" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      transport = SseTransport.new(server)
      transport.should be_a(SseTransport)
    end

    it "implements the Transport interface" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      transport = SseTransport.new(server)
      transport.should be_a(Transport)
    end

    it "has a start method" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      transport = SseTransport.new(server)
      transport.responds_to?(:start).should be_true
    end

    it "has a send method" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      transport = SseTransport.new(server)
      transport.responds_to?(:send).should be_true
    end

    it "has a close method" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      transport = SseTransport.new(server)
      transport.responds_to?(:close).should be_true
    end

    # Note: Testing actual SSE functionality would require
    # mocking HTTP requests and SSE connections, which is beyond the scope of these tests
  end
end
