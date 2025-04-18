require "kemal"
require "json"
require "./mocopo/tools"
require "./mocopo/resources"
require "./mocopo/arguments"

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

    # Initialize a new MCP server
    def initialize(@name : String, @version : String)
      @tool_manager = ToolManager.new
      @resource_manager = ResourceManager.new
      setup_routes
    end

    # Start the server on the specified port
    def start(port = 3000)
      Kemal.run(port)
    end

    # Stop the server
    def stop
      Kemal.stop
    end

    # Register a tool with a block
    def register_tool(name : String, description : String, &block : Tool -> _)
      # Create a schema builder
      schema = {
        "type"       => JSON::Any.new("object"),
        "properties" => JSON::Any.new(Hash(String, JSON::Any).new),
        "required"   => JSON::Any.new([] of JSON::Any),
      }

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

      # Process based on method
      case method
      when "initialize"
        handle_initialize(id, params)
      when "tools/list"
        handle_tools_list(id, params)
      when "tools/call"
        handle_tools_call(id, params)
      when "resources/list"
        handle_resources_list(id, params)
      when "resources/read"
        handle_resources_read(id, params)
      when "resources/subscribe"
        handle_resources_subscribe(id, params)
      else
        error_response(-32601, "Method not found: #{method}", id)
      end
    end

    # Handle initialize request
    private def handle_initialize(id, params)
      # Extract client protocol version
      client_protocol_version = params.try &.["protocolVersion"]?.try &.as_s || "unknown"

      # Check if we support the requested protocol version
      if client_protocol_version != PROTOCOL_VERSION
        # We could negotiate a different version here if needed
        # For now, we just return our supported version
      end

      # Return server capabilities and information
      {
        "jsonrpc" => "2.0",
        "id"      => id,
        "result"  => {
          "protocolVersion" => PROTOCOL_VERSION,
          "capabilities"    => {
            "resources" => {
              "listChanged" => true,
            },
            "tools" => {
              "listChanged" => true,
            },
          },
          "serverInfo" => {
            "name"    => @name,
            "version" => @version,
          },
        },
      }
    end

    # Handle tools/list request
    private def handle_tools_list(id, params)
      # Get all tools
      tools = @tool_manager.list

      # Convert to JSON-compatible format
      tools_json = tools.map(&.to_json_object)

      # Return the list of tools
      {
        "jsonrpc" => "2.0",
        "id"      => id,
        "result"  => {
          "tools" => tools_json,
        },
      }
    end

    # Handle tools/call request
    private def handle_tools_call(id, params)
      # Extract tool name and arguments
      name = params.try &.["name"]?.try &.as_s
      arguments = params.try &.["arguments"]?

      # Check if tool exists
      unless name && @tool_manager.exists?(name)
        return error_response(-32602, "Unknown tool: #{name || "missing name"}", id)
      end

      # Get the tool
      tool = @tool_manager.get(name).not_nil!

      begin
        # Convert arguments to Hash(String, JSON::Any)? if present
        args = arguments.try &.as_h?

        # Execute the tool
        result = tool.execute(args)

        # Return the result
        {
          "jsonrpc" => "2.0",
          "id"      => id,
          "result"  => result,
        }
      rescue ex
        # Handle execution errors
        {
          "jsonrpc" => "2.0",
          "id"      => id,
          "result"  => {
            "content" => [
              {
                "type" => "text",
                "text" => "Error executing tool: #{ex.message}",
              },
            ],
            "isError" => true,
          },
        }
      end
    end

    # Handle resources/list request
    private def handle_resources_list(id, params)
      # Get all resources
      resources = @resource_manager.list

      # Convert to JSON-compatible format
      resources_json = resources.map(&.to_json_object)

      # Return the list of resources
      {
        "jsonrpc" => "2.0",
        "id"      => id,
        "result"  => {
          "resources" => resources_json,
        },
      }
    end

    # Handle resources/read request
    private def handle_resources_read(id, params)
      # Extract resource URI
      uri = params.try &.["uri"]?.try &.as_s

      # Check if resource exists
      unless uri && @resource_manager.exists?(uri)
        return error_response(-32002, "Resource not found: #{uri || "missing uri"}", id)
      end

      begin
        # Get the resource
        resource = @resource_manager.get(uri).not_nil!

        # Get the resource content
        content = resource.get_content

        # Return the content
        {
          "jsonrpc" => "2.0",
          "id"      => id,
          "result"  => {
            "contents" => [content.to_json_object],
          },
        }
      rescue ex
        # Handle content retrieval errors
        error_response(-32603, "Error retrieving resource content: #{ex.message}", id)
      end
    end

    # Handle resources/subscribe request
    private def handle_resources_subscribe(id, params)
      # Extract resource URI
      uri = params.try &.["uri"]?.try &.as_s

      # Check if resource exists
      unless uri && @resource_manager.exists?(uri)
        return error_response(-32002, "Resource not found: #{uri || "missing uri"}", id)
      end

      # Generate a subscriber ID (in a real implementation, this would be tied to the client)
      subscriber_id = Random.new.hex(8)

      # Subscribe to the resource
      @resource_manager.subscribe(uri, subscriber_id)

      # Return success
      {
        "jsonrpc" => "2.0",
        "id"      => id,
        "result"  => {
          "subscribed" => true,
        },
      }
    end

    # Create a JSON-RPC error response
    private def error_response(code, message, id = nil)
      {
        "jsonrpc" => "2.0",
        "id"      => id,
        "error"   => {
          "code"    => code,
          "message" => message,
        },
      }
    end
  end
end
