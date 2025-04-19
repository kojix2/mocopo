require "kemal"
require "json"
require "./mocopo/types"
require "./mocopo/tools"
require "./mocopo/resources"
require "./mocopo/arguments"
require "./mocopo/prompts"
require "./mocopo/context"
require "./mocopo/sampling"
require "./mocopo/roots"
require "./mocopo/cancellation"
require "./mocopo/handlers"
require "./mocopo/json_rpc"
require "./mocopo/notifications"
require "./mocopo/pagination"
require "./mocopo/completion"
require "./mocopo/transport"
require "./mocopo/transport_manager"

# MocoPo - A Crystal library for building MCP (Model Context Protocol) servers
module MocoPo
  VERSION = "0.1.0"

  # MCP protocol version supported by this implementation
  PROTOCOL_VERSION = "2025-03-26"

  # Server class for handling MCP requests
  class Server
    # Tool manager
    getter tool_manager : ToolManager

    # Resource manager
    getter resource_manager : ResourceManager

    # Prompt manager
    getter prompt_manager : PromptManager

    # Sampling manager
    getter sampling_manager : SamplingManager

    # Handler manager
    getter handler_manager : HandlerManager?

    # Notification manager
    getter notification_manager : NotificationManager?

    # Transport manager
    getter transport_manager : TransportManager?

    # Server name
    getter name : String

    # Server version
    getter version : String

    # Initialize a new MCP server
    def initialize(@name : String, @version : String, setup_routes : Bool = true, setup_transports : Bool = true)
      # Create managers
      @tool_manager = ToolManager.new
      @resource_manager = ResourceManager.new
      @prompt_manager = PromptManager.new
      @sampling_manager = SamplingManager.new
      @root_manager = RootManager.new
      @cancellation_manager = CancellationManager.new

      # Create notification manager
      notification_mgr = NotificationManager.new(self)
      @notification_manager = notification_mgr

      # Set server reference in managers
      @tool_manager.server = self
      @resource_manager.server = self
      @prompt_manager.server = self

      # Create handler manager
      @handler_manager = HandlerManager.new(self)

      # Create transport manager
      @transport_manager = TransportManager.new(self)

      # Setup routes (for backward compatibility)
      setup_routes if setup_routes

      # Setup default transports
      setup_default_transports if setup_transports
    end

    # Start the server on the specified port
    def start(port = 3000)
      # Start all transports
      if transport_manager = @transport_manager
        transport_manager.start_all
      end

      # Start Kemal (for backward compatibility)
      Kemal.run(port)
    end

    # Stop the server
    def stop
      # Stop all transports
      if transport_manager = @transport_manager
        transport_manager.close_all
      end

      # Stop Kemal (for backward compatibility)
      Kemal.stop
    end

    # Register a tool with a block
    def register_tool(name : String, description : String, &block : Tool -> _)
      # Create a schema builder
      schema = {
        "type"       => "object",
        "properties" => {} of String => JsonValue,
        "required"   => [] of JsonValue,
      } of String => JsonValue

      # Create a tool
      tool = Tool.new(name, description, schema)

      # Register the tool
      @tool_manager.register(tool)

      # Yield the tool to the block
      yield tool

      # Return the tool for further configuration
      tool
    end

    # Register a tool without a block
    def register_tool(name : String, description : String)
      # Call the block version with an empty block
      register_tool(name, description) { |_| }
    end

    # Register a resource with a block
    def register_resource(uri : String, name : String, description : String? = nil, mime_type : String? = nil, size : Int64? = nil, &block : Resource -> _)
      # Create a resource
      resource = Resource.new(uri, name, description, mime_type, size)

      # Register the resource
      @resource_manager.register(resource)

      # Yield the resource to the block
      yield resource

      # Return the resource for further configuration
      resource
    end

    # Register a resource without a block
    def register_resource(uri : String, name : String, description : String? = nil, mime_type : String? = nil, size : Int64? = nil)
      # Call the block version with an empty block
      register_resource(uri, name, description, mime_type, size) { |_| }
    end

    # Register a prompt with a block
    def register_prompt(name : String, description : String? = nil, &block : Prompt -> _)
      # Create a prompt
      prompt = Prompt.new(name, description)

      # Register the prompt
      @prompt_manager.register(prompt)

      # Yield the prompt to the block
      yield prompt

      # Return the prompt for further configuration
      prompt
    end

    # Register a prompt without a block
    def register_prompt(name : String, description : String? = nil)
      # Call the block version with an empty block
      register_prompt(name, description) { |_| }
    end

    # Setup default transports
    private def setup_default_transports
      # Create HTTP transport (for backward compatibility)
      if transport_manager = @transport_manager
        transport_manager.create_http_transport
      end
    end

    # Create and register a transport
    def register_transport(transport : Transport) : Transport
      if transport_manager = @transport_manager
        transport_manager.register(transport)
      else
        raise "Transport manager not initialized"
      end
    end

    # Create and register an HTTP transport
    def create_http_transport : HttpTransport
      if transport_manager = @transport_manager
        transport_manager.create_http_transport
      else
        raise "Transport manager not initialized"
      end
    end

    # Create and register a stdio transport
    def create_stdio_transport : StdioTransport
      if transport_manager = @transport_manager
        transport_manager.create_stdio_transport
      else
        raise "Transport manager not initialized"
      end
    end

    # Create and register an SSE transport
    def create_sse_transport : SseTransport
      if transport_manager = @transport_manager
        transport_manager.create_sse_transport
      else
        raise "Transport manager not initialized"
      end
    end

    # Setup routes for backward compatibility
    private def setup_routes
      # JSON-RPC endpoint
      post "/mcp" do |env|
        begin
          # Parse JSON-RPC request
          request_body = env.request.body.try &.gets_to_end
          next error_response(400, "Missing request body").to_json unless request_body

          # Parse as JSON
          json = JSON.parse(request_body)

          # Process JSON-RPC request
          response = process_jsonrpc(json)

          # Return JSON-RPC response
          env.response.content_type = "application/json"
          response.to_json
        rescue ex : JSON::ParseException
          env.response.status_code = 400
          next error_response(-32700, "Parse error: #{ex.message}").to_json
        rescue ex
          env.response.status_code = 500
          next error_response(-32603, "Internal error: #{ex.message}").to_json
        end
      end
    end

    # Process a JSON-RPC request and return a response
    private def process_jsonrpc(json)
      # Ensure it's a valid JSON-RPC 2.0 request
      return error_response(-32600, "Invalid Request") unless json["jsonrpc"]? == "2.0"

      # Extract request fields
      id = json["id"]?
      method = json["method"]?.try &.as_s
      params = json["params"]?

      # Handle method not found
      return error_response(-32601, "Method not found", id) unless method

      # Process using handler manager if available
      if handler_manager = @handler_manager
        handler_manager.handle_request(method, id, params)
      else
        # Fallback to error response if handler manager is not available
        error_response(-32603, "Handler manager not initialized", id)
      end
    end

    # Create a JSON-RPC error response
    private def error_response(code : Int32, message : String, id : JsonRpcId = nil)
      JsonRpcErrorResponse.new(JsonRpcError.new(code, message), id).to_json_object
    end
  end
end
