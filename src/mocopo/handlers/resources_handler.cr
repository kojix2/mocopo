module MocoPo
  # Handler for resources methods
  class ResourcesHandler < BaseHandler
    # Handle resources/list request
    def handle_list(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Get all resources
      resources = @server.resource_manager.list

      # Convert to JSON-compatible format
      resources_json = resources.map(&.to_json_object)

      # Return the list of resources
      success_response(id, {
        "resources" => resources_json,
      })
    end

    # Handle resources/read request
    def handle_read(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract resource URI
      uri = params.try &.["uri"]?.try &.as_s

      # Check if resource exists
      unless uri && @server.resource_manager.exists?(uri)
        return error_response(-32002, "Resource not found: #{uri || "missing uri"}", id)
      end

      begin
        # Get the resource
        resource = @server.resource_manager.get(uri).not_nil!

        # Create a context for the resource access
        request_id = id.to_s
        client_id = "client-#{Random.new.hex(4)}" # In a real implementation, this would be tied to the client
        context = Context.new(request_id, client_id, @server)

        # Get the resource content with context
        content = resource.get_content(context)

        # Return the content
        success_response(id, {
          "contents" => [content.to_json_object],
        })
      rescue ex
        # Handle content retrieval errors
        error_response(-32603, "Error retrieving resource content: #{ex.message}", id)
      end
    end

    # Handle resources/subscribe request
    def handle_subscribe(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract resource URI
      uri = params.try &.["uri"]?.try &.as_s

      # Check if resource exists
      unless uri && @server.resource_manager.exists?(uri)
        return error_response(-32002, "Resource not found: #{uri || "missing uri"}", id)
      end

      # Generate a subscriber ID (in a real implementation, this would be tied to the client)
      subscriber_id = Random.new.hex(8)

      # Subscribe to the resource
      @server.resource_manager.subscribe(uri, subscriber_id)

      # Return success
      success_response(id, {
        "subscribed" => true,
      })
    end

    # Handle a JSON-RPC request
    def handle(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # This method should not be called directly
      error_response(-32603, "ResourcesHandler.handle called directly", id)
    end
  end
end
