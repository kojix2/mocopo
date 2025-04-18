module MocoPo
  # Handler for tools methods
  class ToolsHandler < BaseHandler
    # Handle tools/list request
    def handle_list(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract cursor from params
      cursor = params.try &.["cursor"]?.try &.as_s

      # Get all tools
      tools = @server.tool_manager.list

      # Apply pagination
      page_tools, next_cursor = Pagination.paginate(tools, cursor)

      # Convert to JSON-compatible format
      tools_json = page_tools.map(&.to_json_object)

      # Build response
      response = {"tools" => tools_json}

      # Add next cursor if there are more results
      response["nextCursor"] = next_cursor if next_cursor

      # Return the list of tools
      success_response(id, response)
    end

    # Handle tools/call request
    def handle_call(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract tool name and arguments
      name = params.try &.["name"]?.try &.as_s
      arguments = params.try &.["arguments"]?

      # Check if tool exists
      unless name && @server.tool_manager.exists?(name)
        return error_response(-32602, "Unknown tool: #{name || "missing name"}", id)
      end

      # Get the tool
      tool = @server.tool_manager.get(name).not_nil!

      begin
        # Convert arguments to Hash(String, JSON::Any)? if present
        args = arguments.try &.as_h?

        # Create a context for the tool execution
        request_id = id.to_s
        client_id = "client-#{Random.new.hex(4)}" # In a real implementation, this would be tied to the client
        context = Context.new(request_id, client_id, @server)

        # Execute the tool with context
        result = tool.execute(args, context)

        # Return the result
        success_response(id, result)
      rescue ex
        # Handle execution errors
        success_response(id, {
          "content" => [
            {
              "type" => "text",
              "text" => "Error executing tool: #{ex.message}",
            },
          ],
          "isError" => true,
        })
      end
    end

    # Handle a JSON-RPC request
    def handle(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # This method should not be called directly
      error_response(-32603, "ToolsHandler.handle called directly", id)
    end
  end
end
