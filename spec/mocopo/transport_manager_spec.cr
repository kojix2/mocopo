require "../spec_helper"

module MocoPo
  describe TransportManager do
    it "can be initialized with a server" do
      server = Server.new("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
      manager = TransportManager.new(server)
      manager.should be_a(TransportManager)
    end
  end
end
