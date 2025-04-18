module MocoPo
  # Manages handlers for JSON-RPC methods
  class HandlerManager
    # Server instance
    @server : Server

    # Method handlers
    @handlers : Hash(String, BaseHandler)

    # Method to handler method mappings
    @method_mappings : Hash(String, Tuple(BaseHandler, Symbol))

    # Initialize a new handler manager
    def initialize(@server : Server)
      @handlers = {} of String => BaseHandler
      @method_mappings = {} of String => Tuple(BaseHandler, Symbol)
      setup_handlers
    end

    # Set up default handlers
    private def setup_handlers
      # Create handlers
      initialize_handler = InitializeHandler.new(@server)
      tools_handler = ToolsHandler.new(@server)
      resources_handler = ResourcesHandler.new(@server)
      prompts_handler = PromptsHandler.new(@server)

      # Register handlers
      register_handler("initialize", initialize_handler)
      register_handler("tools", tools_handler)
      register_handler("resources", resources_handler)
      register_handler("prompts", prompts_handler)

      # Register method mappings
      register_method("initialize", initialize_handler, :handle)
      register_method("tools/list", tools_handler, :handle_list)
      register_method("tools/call", tools_handler, :handle_call)
      register_method("resources/list", resources_handler, :handle_list)
      register_method("resources/read", resources_handler, :handle_read)
      register_method("resources/subscribe", resources_handler, :handle_subscribe)
      register_method("prompts/list", prompts_handler, :handle_list)
      register_method("prompts/get", prompts_handler, :handle_get)
    end

    # Register a handler
    def register_handler(name : String, handler : BaseHandler)
      @handlers[name] = handler
    end

    # Register a method mapping
    def register_method(method : String, handler : BaseHandler, handler_method : Symbol)
      @method_mappings[method] = {handler, handler_method}
    end

    # Handle a JSON-RPC request
    def handle_request(method : String, id, params) : Hash(String, JSON::Any | Array(JSON::Any) | Hash(String, JSON::Any) | String | Int32 | Bool | Nil)
      # Check if method exists
      if @method_mappings.has_key?(method)
        # Get handler and method
        handler, method_symbol = @method_mappings[method]

        # Call handler method based on method symbol
        case method_symbol
        when :handle
          handler.handle(id, params)
        when :handle_list
          handler.handle_list(id, params)
        when :handle_call
          handler.handle_call(id, params)
        when :handle_read
          handler.handle_read(id, params)
        when :handle_subscribe
          handler.handle_subscribe(id, params)
        when :handle_get
          handler.handle_get(id, params)
        else
          handler.handle(id, params)
        end
      else
        # Method not found
        {
          "jsonrpc" => "2.0",
          "id"      => id,
          "error"   => {
            "code"    => -32601,
            "message" => "Method not found: #{method}",
          },
        }
      end
    end
  end
end
