require "../spec_helper"

module MocoPo
  describe TransportManager do
    it "can be initialized with a server" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      manager = TransportManager.new(server)
      manager.should be_a(TransportManager)
    end

    it "can register a transport" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      manager = TransportManager.new(server)
      transport = TestTransport.new

      registered = manager.register(transport)
      registered.should be(transport)
    end

    it "sets up message handler when registering a transport" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      manager = TransportManager.new(server)
      transport = TestTransport.new

      manager.register(transport)
      transport.on_message.should_not be_nil
    end

    it "sets up error handler when registering a transport" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      manager = TransportManager.new(server)
      transport = TestTransport.new

      manager.register(transport)
      transport.on_error.should_not be_nil
    end

    it "sets up close handler when registering a transport" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      manager = TransportManager.new(server)
      transport = TestTransport.new

      manager.register(transport)
      transport.on_close.should_not be_nil
    end

    it "can create and register an HTTP transport" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      manager = TransportManager.new(server)

      transport = manager.create_http_transport
      transport.should be_a(HttpTransport)
    end

    it "can create and register a stdio transport" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      manager = TransportManager.new(server)

      transport = manager.create_stdio_transport
      transport.should be_a(StdioTransport)
    end

    it "can create and register an SSE transport" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      manager = TransportManager.new(server)

      transport = manager.create_sse_transport
      transport.should be_a(SseTransport)
    end

    it "can start all registered transports" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      manager = TransportManager.new(server)
      transport = TestTransport.new

      manager.register(transport)
      manager.start_all

      transport.started.should be_true
    end

    it "can close all registered transports" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      manager = TransportManager.new(server)
      transport = TestTransport.new

      manager.register(transport)
      manager.close_all

      transport.closed.should be_true
    end
  end
end
