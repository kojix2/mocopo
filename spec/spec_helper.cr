require "spec"
require "../src/mocopo"

# Helper method to create a server for testing without setting up routes
def create_test_server(name : String = "TestServer", version : String = "1.0.0")
  # Create a server with setup_routes set to false
  MocoPo::Server.new(name, version, false)
end
