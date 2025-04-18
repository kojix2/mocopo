module MocoPo
  # Handler for cancellation methods
  class CancellationHandler < BaseHandler
    # Handle cancellation/create request
    def handle_create(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      begin
        # Create a new token
        token_id = params.try { |p| MocoPo.safe_string(p["id"]?) }
        token = @server.create_cancellation_token(token_id)

        # Return the token
        success_response(id, token.to_json_object)
      rescue ex
        # Handle errors
        error_response(-32603, "Error creating cancellation token: #{ex.message || "Unknown error"}", id)
      end
    end

    # Handle cancellation/cancel request
    def handle_cancel(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      begin
        # Validate parameters
        unless params
          return error_response(-32602, "Missing parameters", id)
        end

        # Extract token ID and reason
        token_id = params.try { |p| MocoPo.safe_string(p["id"]?) }
        reason = params.try { |p| MocoPo.safe_string(p["reason"]?) }

        # Validate token ID
        unless token_id
          return error_response(-32602, "Missing token ID", id)
        end

        # Cancel the token
        success = @server.cancel_token(token_id, reason)

        # Return success or error
        if success
          success_response(id, {"success" => true} of String => JsonValue)
        else
          error_response(-32602, "Token not found: #{token_id}", id)
        end
      rescue ex
        # Handle errors
        error_response(-32603, "Error cancelling token: #{ex.message || "Unknown error"}", id)
      end
    end

    # Handle cancellation/status request
    def handle_status(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      begin
        # Validate parameters
        unless params
          return error_response(-32602, "Missing parameters", id)
        end

        # Extract token ID
        token_id = params.try { |p| MocoPo.safe_string(p["id"]?) }

        # Validate token ID
        unless token_id
          return error_response(-32602, "Missing token ID", id)
        end

        # Get the token
        token = @server.cancellation_manager.get_token(token_id)

        # Return token status or error
        if token
          success_response(id, token.to_json_object)
        else
          error_response(-32602, "Token not found: #{token_id}", id)
        end
      rescue ex
        # Handle errors
        error_response(-32603, "Error getting token status: #{ex.message || "Unknown error"}", id)
      end
    end

    # Handle cancellation/list request
    def handle_list(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      begin
        # Get all tokens
        tokens = @server.cancellation_manager.list

        # Convert to JSON-compatible format
        tokens_array = [] of JsonValue
        tokens.each do |token|
          tokens_array << token.to_json_object
        end

        # Return the list of tokens
        result = {} of String => JsonValue
        result["tokens"] = tokens_array
        success_response(id, result)
      rescue ex
        # Handle errors
        error_response(-32603, "Error listing tokens: #{ex.message || "Unknown error"}", id)
      end
    end

    # Handle a JSON-RPC request
    def handle(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # This method should not be called directly
      error_response(-32603, "CancellationHandler.handle called directly", id)
    end

    # Handle a JSON-RPC request with method
    def handle(id : JsonRpcId, method : String, params : JsonRpcParams) : JsonObject
      case method
      when "cancellation/create"
        handle_create(id, params)
      when "cancellation/cancel"
        handle_cancel(id, params)
      when "cancellation/status"
        handle_status(id, params)
      when "cancellation/list"
        handle_list(id, params)
      else
        error_response(-32601, "Method not found: #{method}", id)
      end
    end
  end
end
