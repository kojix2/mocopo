module MocoPo
  # Handler for tools methods
  class ToolsHandler < BaseHandler
    # Handle tools/list request
    def handle_list(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract cursor from params
      cursor = get_string_param(params, "cursor")

      # Get all tools
      tools = @server.tool_manager.list

      # Apply pagination
      page_tools, next_cursor = Pagination.paginate(tools, cursor)

      # Build response with explicit type
      response = {} of String => JsonValue

      # Add tools array
      tools_array = [] of JsonValue
      page_tools.each do |tool|
        # Convert tool.to_json_object to JsonValue
        tool_json = tool.to_json_object
        tool_json_str = tool_json.to_json
        tool_json_value = JSON.parse(tool_json_str).as_h

        # Convert to JsonValue
        tool_value = {} of String => JsonValue
        tool_json_value.each do |k, v|
          tool_value[k] = Utils.to_json_value(v)
        end

        tools_array << tool_value
      end
      response["tools"] = tools_array

      # Add next cursor if there are more results
      response["nextCursor"] = next_cursor if next_cursor

      # Return the list of tools with automatic conversion to JsonValue
      safe_success_response(id, response)
    end

    # Handle tools/call request
    def handle_call(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract tool name and arguments
      name = get_string_param(params, "name")
      arguments = get_hash_param(params, "arguments")

      # Check if tool exists
      unless name && @server.tool_manager.exists?(name)
        return error_response(-32602, "Unknown tool: #{name || "missing name"}", id)
      end

      # Get the tool
      tool = @server.tool_manager.get(name).not_nil!

      begin
        # Convert arguments to Hash(String, JSON::Any)? if needed
        json_args = nil
        if arguments
          # Use the helper method to convert JsonValue to JSON::Any
          json_args = {} of String => JSON::Any
          arguments.each do |key, value|
            json_args[key] = json_value_to_json_any(value)
          end
        end

        # Create a context for the tool execution
        request_id = id.to_s
        client_id = "client-#{Random.new.hex(4)}" # In a real implementation, this would be tied to the client
        context = Context.new(request_id, client_id, @server)

        # Execute the tool with context
        raw_result = tool.execute(json_args, context)

        # Build result with automatic conversion to JsonValue
        result = {
          "content" => raw_result["content"]?.try do |content|
            if content.is_a?(Array)
              content.map do |item|
                if item.is_a?(Hash)
                  item_hash = {} of String => String | Bool
                  item.each { |k, v| item_hash[k] = v }
                  item_hash
                else
                  {} of String => String
                end
              end
            else
              [] of Hash(String, String)
            end
          end || [] of Hash(String, String),
          "isError" => raw_result["isError"]? == "true",
        }

        # Return the result with automatic conversion to JsonValue
        safe_success_response(id, result)
      rescue ex
        # Handle execution errors
        error_result = {
          "content" => [
            {
              "type" => "text",
              "text" => "Error executing tool: #{ex.message}",
            },
          ],
          "isError" => true,
        }

        # Return error result with automatic conversion to JsonValue
        safe_success_response(id, error_result)
      end
    end

    # Handle a JSON-RPC request
    def handle(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # This method should not be called directly
      error_response(-32603, "ToolsHandler.handle called directly", id)
    end
  end
end
