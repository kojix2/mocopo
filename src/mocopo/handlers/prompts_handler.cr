module MocoPo
  # Handler for prompts methods
  class PromptsHandler < BaseHandler
    # Handle prompts/list request
    def handle_list(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract cursor from params
      cursor = params.try &.["cursor"]?.try &.as_s

      # Get all prompts
      prompts = @server.prompt_manager.list

      # Apply pagination
      page_prompts, next_cursor = Pagination.paginate(prompts, cursor)

      # Convert to JSON-compatible format
      prompts_json = page_prompts.map(&.to_json_object)

      # Build response
      response = {"prompts" => prompts_json}

      # Add next cursor if there are more results
      response["nextCursor"] = next_cursor if next_cursor

      # Return the list of prompts
      success_response(id, response)
    end

    # Handle prompts/get request
    def handle_get(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract prompt name and arguments
      name = params.try &.["name"]?.try &.as_s
      arguments = params.try &.["arguments"]?

      # Check if prompt exists
      unless name && @server.prompt_manager.exists?(name)
        return error_response(-32602, "Unknown prompt: #{name || "missing name"}", id)
      end

      # Get the prompt
      prompt = @server.prompt_manager.get(name).not_nil!

      begin
        # Convert arguments to Hash(String, JSON::Any)? if present
        args = arguments.try &.as_h?

        # Execute the prompt
        messages = prompt.execute(args)
        messages_json = messages.map(&.to_json_object)

        # Return the result
        success_response(id, {
          "description" => prompt.description,
          "messages"    => messages_json,
        })
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
