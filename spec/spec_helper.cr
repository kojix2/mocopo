require "spec"
require "../src/mocopo"

# Mock server class for testing
module MocoPo
  class TestServer < Server
    def initialize(@name : String, @version : String)
      @tool_manager = ToolManager.new
      @resource_manager = ResourceManager.new
      @prompt_manager = PromptManager.new
      # Skip setup_routes to avoid Kemal route conflicts
    end
  end
end

# Helper method to create a server for testing without setting up routes
def create_test_server(name : String = "TestServer", version : String = "1.0.0")
  MocoPo::TestServer.new(name, version)
end
