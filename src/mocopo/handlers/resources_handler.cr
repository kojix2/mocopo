module MocoPo
  # Handler for resources methods
  class ResourcesHandler < BaseHandler
    # Handle resources/list request
    def handle_list(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract cursor from params
      cursor = get_string_param(params, "cursor")

      # Get all resources
      resources = @server.resource_manager.list

      # Apply pagination
      page_resources, next_cursor = Pagination.paginate(resources, cursor)

      # Build response with explicit type
      response = {} of String => JsonValue

      # Add resources array
      resources_array = [] of JsonValue
      page_resources.each do |resource|
        # Convert resource.to_json_object to JsonValue
        resource_json = resource.to_json_object
        resource_json_str = resource_json.to_json
        resource_json_value = JSON.parse(resource_json_str).as_h

        # Convert to JsonValue
        resource_value = {} of String => JsonValue
        resource_json_value.each do |k, v|
          resource_value[k] = Utils.to_json_value(v)
        end

        resources_array << resource_value
      end
      response["resources"] = resources_array

      # Add next cursor if there are more results
      response["nextCursor"] = next_cursor if next_cursor

      # Return the list of resources with automatic conversion to JsonValue
      safe_success_response(id, response)
    end

    # Handle resources/read request
    def handle_read(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract resource URI
      uri = get_string_param(params, "uri")

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

        # Build response with explicit type
        response = {} of String => JsonValue

        # Add contents array
        contents_array = [] of JsonValue

        # Convert content.to_json_object to JsonValue
        content_json = content.to_json_object
        content_json_str = content_json.to_json
        content_json_value = JSON.parse(content_json_str).as_h

        # Convert to JsonValue
        content_value = {} of String => JsonValue
        content_json_value.each do |k, v|
          content_value[k] = Utils.to_json_value(v)
        end

        contents_array << content_value
        response["contents"] = contents_array

        # Return the content with automatic conversion to JsonValue
        success_response(id, response)
      rescue ex
        # Handle content retrieval errors
        error_response(-32603, "Error retrieving resource content: #{ex.message}", id)
      end
    end

    # Handle resources/subscribe request
    def handle_subscribe(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract resource URI
      uri = get_string_param(params, "uri")

      # Check if resource exists
      unless uri && @server.resource_manager.exists?(uri)
        return error_response(-32002, "Resource not found: #{uri || "missing uri"}", id)
      end

      # Generate a subscriber ID (in a real implementation, this would be tied to the client)
      subscriber_id = Random.new.hex(8)

      # Subscribe to the resource
      @server.resource_manager.subscribe(uri, subscriber_id)

      # Build response with explicit type
      response = {} of String => JsonValue
      response["subscribed"] = true

      # Return success with automatic conversion to JsonValue
      success_response(id, response)
    end

    # Handle a JSON-RPC request
    def handle(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # This method should not be called directly
      error_response(-32603, "ResourcesHandler.handle called directly", id)
    end
  end
end
