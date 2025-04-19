module MocoPo
  # Handler for prompts methods
  class PromptsHandler < BaseHandler
    # Handle prompts/list request
    def handle_list(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract cursor from params
      cursor = get_string_param(params, "cursor")

      # Get all prompts
      prompts = @server.prompt_manager.list

      # Apply pagination
      page_prompts, next_cursor = Pagination.paginate(prompts, cursor)

      # Build response with explicit type
      response = {} of String => JsonValue

      # Add prompts array
      prompts_array = [] of JsonValue
      page_prompts.each do |prompt|
        # Convert prompt.to_json_object to JsonValue
        prompt_json = prompt.to_json_object
        prompt_json_str = prompt_json.to_json
        prompt_json_value = JSON.parse(prompt_json_str).as_h

        # Convert to JsonValue
        prompt_value = {} of String => JsonValue
        prompt_json_value.each do |k, v|
          prompt_value[k] = Utils.to_json_value(v)
        end

        prompts_array << prompt_value
      end
      response["prompts"] = prompts_array

      # Add next cursor if there are more results
      response["nextCursor"] = next_cursor if next_cursor

      # Return the list of prompts with automatic conversion to JsonValue
      safe_success_response(id, response)
    end

    # Handle prompts/get request
    def handle_get(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract prompt name and arguments
      name = get_string_param(params, "name")
      arguments = get_hash_param(params, "arguments")

      # Check if prompt exists
      unless name && @server.prompt_manager.exists?(name)
        return error_response(-32602, "Unknown prompt: #{name || "missing name"}", id)
      end

      # Get the prompt
      prompt = @server.prompt_manager.get(name).not_nil!

      begin
        # Use arguments directly as JsonObject
        json_args = arguments

        # Execute the prompt
        messages = prompt.execute(json_args)

        # Build result with explicit type
        result = {} of String => JsonValue
        result["description"] = prompt.description

        # Add messages array
        messages_array = [] of JsonValue
        messages.each do |message|
          # Convert message.to_json_object to JsonValue
          message_json = message.to_json_object
          message_json_str = message_json.to_json
          message_json_value = JSON.parse(message_json_str).as_h

          # Convert to JsonValue
          message_value = {} of String => JsonValue
          message_json_value.each do |k, v|
            message_value[k] = Utils.to_json_value(v)
          end

          messages_array << message_value
        end
        result["messages"] = messages_array

        # Return the result
        success_response(id, result)
      rescue ex
        # Handle execution errors
        error_response(-32603, "Error executing prompt: #{ex.message}", id)
      end
    end

    # Handle a JSON-RPC request
    def handle(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # This method should not be called directly
      error_response(-32603, "PromptsHandler.handle called directly", id)
    end
  end
end
