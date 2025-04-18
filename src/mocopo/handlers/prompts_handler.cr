module MocoPo
  # Handler for prompts methods
  class PromptsHandler < BaseHandler
    # Handle prompts/list request
    def handle_list(id, params) : Hash(String, JSON::Any | Array(JSON::Any) | Hash(String, JSON::Any) | String | Int32 | Bool | Nil)
      # Get all prompts
      prompts = @server.prompt_manager.list

      # Convert to JSON-compatible format
      prompts_json = prompts.map(&.to_json_object)

      # Return the list of prompts
      success_response(id, {
        "prompts" => prompts_json,
      })
    end

    # Handle prompts/get request
    def handle_get(id, params) : Hash(String, JSON::Any | Array(JSON::Any) | Hash(String, JSON::Any) | String | Int32 | Bool | Nil)
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
    def handle(id, params) : Hash(String, JSON::Any | Array(JSON::Any) | Hash(String, JSON::Any) | String | Int32 | Bool | Nil)
      # This method should not be called directly
      error_response(-32603, "PromptsHandler.handle called directly", id)
    end
  end
end
