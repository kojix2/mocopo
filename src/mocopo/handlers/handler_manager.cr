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
      sampling_handler = SamplingHandler.new(@server)
      roots_handler = RootsHandler.new(@server)
      cancellation_handler = CancellationHandler.new(@server)
      completion_handler = CompletionHandler.new(@server)

      # Register handlers
      register_handler("initialize", initialize_handler)
      register_handler("tools", tools_handler)
      register_handler("resources", resources_handler)
      register_handler("prompts", prompts_handler)
      register_handler("sampling", sampling_handler)
      register_handler("roots", roots_handler)
      register_handler("cancellation", cancellation_handler)
      register_handler("completion", completion_handler)

      # Register method mappings
      register_method("initialize", initialize_handler, :handle)
      register_method("tools/list", tools_handler, :handle_list)
      register_method("tools/call", tools_handler, :handle_call)
      register_method("resources/list", resources_handler, :handle_list)
      register_method("resources/read", resources_handler, :handle_read)
      register_method("resources/subscribe", resources_handler, :handle_subscribe)
      register_method("prompts/list", prompts_handler, :handle_list)
      register_method("prompts/get", prompts_handler, :handle_get)
      register_method("sampling/list", sampling_handler, :handle_list)
      register_method("sampling/sample", sampling_handler, :handle_sample)
      register_method("sampling/createMessage", sampling_handler, :handle_create_message)
      register_method("roots/list", roots_handler, :handle_list)
      register_method("roots/listDirectory", roots_handler, :handle_list_directory)
      register_method("roots/readFile", roots_handler, :handle_read_file)
      register_method("roots/writeFile", roots_handler, :handle_write_file)
      register_method("roots/deleteFile", roots_handler, :handle_delete_file)
      register_method("roots/createDirectory", roots_handler, :handle_create_directory)
      register_method("roots/deleteDirectory", roots_handler, :handle_delete_directory)
      register_method("cancellation/create", cancellation_handler, :handle_create)
      register_method("cancellation/cancel", cancellation_handler, :handle_cancel)
      register_method("cancellation/status", cancellation_handler, :handle_status)
      register_method("cancellation/list", cancellation_handler, :handle_list)
      register_method("completion/complete", completion_handler, :handle_complete)
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
    def handle_request(method : String, id : JsonRpcId, params : JsonRpcParams) : JsonObject
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
        when :handle_sample
          handler.handle_sample(id, params)
        when :handle_create_message
          handler.handle_create_message(id, params)
        when :handle_list_directory
          handler.handle_list_directory(id, params)
        when :handle_read_file
          handler.handle_read_file(id, params)
        when :handle_write_file
          handler.handle_write_file(id, params)
        when :handle_delete_file
          handler.handle_delete_file(id, params)
        when :handle_create_directory
          handler.handle_create_directory(id, params)
        when :handle_delete_directory
          handler.handle_delete_directory(id, params)
        when :handle_create
          handler.handle_create(id, params)
        when :handle_cancel
          handler.handle_cancel(id, params)
        when :handle_status
          handler.handle_status(id, params)
        when :handle_complete
          handler.handle_complete(id, params)
        else
          handler.handle(id, params)
        end
      else
        # Method not found
        JsonRpcErrorResponse.new(
          JsonRpcError.new(-32601, "Method not found: #{method}"),
          id
        ).to_json_object
      end
    end
  end
end
