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
        if method_symbol == :handle
          # All handlers must implement handle
          handler.handle(id, params)
        else
          # Call the specific handler method using a safer approach with responds_to?
          case method_symbol
          when :handle_list
            # Handle each handler type individually to avoid type casting issues
            if handler.is_a?(ToolsHandler)
              handler.handle_list(id, params)
            elsif handler.is_a?(ResourcesHandler)
              handler.handle_list(id, params)
            elsif handler.is_a?(PromptsHandler)
              handler.handle_list(id, params)
            elsif handler.is_a?(SamplingHandler)
              handler.handle_list(id, params)
            elsif handler.is_a?(RootsHandler)
              handler.handle_list(id, params)
            elsif handler.is_a?(CancellationHandler)
              handler.handle_list(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_call
            if handler.responds_to?(:handle_call)
              handler.as(ToolsHandler).handle_call(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_read
            if handler.responds_to?(:handle_read)
              handler.as(ResourcesHandler).handle_read(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_subscribe
            if handler.responds_to?(:handle_subscribe)
              handler.as(ResourcesHandler).handle_subscribe(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_get
            if handler.responds_to?(:handle_get)
              handler.as(PromptsHandler).handle_get(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_sample
            if handler.responds_to?(:handle_sample)
              handler.as(SamplingHandler).handle_sample(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_create_message
            if handler.responds_to?(:handle_create_message)
              handler.as(SamplingHandler).handle_create_message(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_list_directory
            if handler.responds_to?(:handle_list_directory)
              handler.as(RootsHandler).handle_list_directory(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_read_file
            if handler.responds_to?(:handle_read_file)
              handler.as(RootsHandler).handle_read_file(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_write_file
            if handler.responds_to?(:handle_write_file)
              handler.as(RootsHandler).handle_write_file(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_delete_file
            if handler.responds_to?(:handle_delete_file)
              handler.as(RootsHandler).handle_delete_file(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_create_directory
            if handler.responds_to?(:handle_create_directory)
              handler.as(RootsHandler).handle_create_directory(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_delete_directory
            if handler.responds_to?(:handle_delete_directory)
              handler.as(RootsHandler).handle_delete_directory(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_create
            if handler.responds_to?(:handle_create)
              handler.as(CancellationHandler).handle_create(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_cancel
            if handler.responds_to?(:handle_cancel)
              handler.as(CancellationHandler).handle_cancel(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_status
            if handler.responds_to?(:handle_status)
              handler.as(CancellationHandler).handle_status(id, params)
            else
              handler.handle(id, params)
            end
          when :handle_complete
            if handler.responds_to?(:handle_complete)
              handler.as(CompletionHandler).handle_complete(id, params)
            else
              handler.handle(id, params)
            end
          else
            # Fallback to handle method
            handler.handle(id, params)
          end
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
