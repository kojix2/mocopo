module MocoPo
  # Handler for sampling methods
  class SamplingHandler < BaseHandler
    # Handle sampling/list request
    def handle_list(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Get all sampling methods
      methods = @server.sampling_manager.list

      # Convert to JSON-compatible format
      methods_array = [] of JsonValue
      methods.each do |method|
        methods_array << method.to_json_object
      end

      # Return the list of sampling methods
      result = {} of String => JsonValue
      result["methods"] = methods_array
      success_response(id, result)
    end

    # Handle sampling/sample request
    def handle_sample(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract method name and text
      method_name = MocoPo.safe_string(params.try &.["method"]?)
      text = MocoPo.safe_string(params.try &.["text"]?)
      parameters = MocoPo.safe_hash(params.try &.["parameters"]?)

      # Validate parameters
      unless method_name && @server.sampling_manager.exists?(method_name)
        return error_response(-32602, "Unknown sampling method: #{method_name || "missing method"}", id)
      end

      unless text
        return error_response(-32602, "Missing text parameter", id)
      end

      # Get the sampling method
      method = @server.sampling_manager.get(method_name).not_nil!

      begin
        # Create a context for the sampling execution
        request_id = id.to_s
        client_id = "client-#{Random.new.hex(4)}" # In a real implementation, this would be tied to the client
        context = Context.new(request_id, client_id, @server)

        # Execute sampling
        result = method.sample(text, parameters, context)

        # Return the result
        success_response(id, result)
      rescue ex
        # Handle execution errors
        error_response(-32603, "Error sampling: #{ex.message}", id)
      end
    end

    # Handle sampling/createMessage request
    def handle_create_message(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      begin
        # Validate parameters
        unless params
          return error_response(-32602, "Missing parameters", id)
        end

        # Parse the sampling request
        request = SamplingRequest.from_json_object(params)

        # Validate the request
        validation_error = validate_request(request)
        if validation_error
          return error_response(-32602, validation_error, id)
        end

        # Create a context for the sampling execution
        request_id = id.to_s
        client_id = "client-#{Random.new.hex(4)}" # In a real implementation, this would be tied to the client
        context = Context.new(request_id, client_id, @server)

        # Log the request
        context.info("Processing sampling/createMessage request")

        # Create the message
        response = @server.sampling_manager.create_message(request, context)

        # Return the result
        success_response(id, response.to_json_object)
      rescue ex : SamplingError
        # Handle sampling errors
        error_response(ex.code, ex.message, id)
      rescue ex
        # Handle other errors
        error_response(-32603, "Error creating message: #{ex.message}", id)
      end
    end

    # Validate a sampling request
    private def validate_request(request : SamplingRequest) : String?
      # Check if messages are provided
      if request.messages.empty?
        return "No messages provided"
      end

      # Check if max_tokens is valid
      if request.max_tokens <= 0
        return "Invalid maxTokens: must be greater than 0"
      end

      # Check if temperature is valid (if provided)
      if request.temperature && (request.temperature < 0.0 || request.temperature > 1.0)
        return "Invalid temperature: must be between 0.0 and 1.0"
      end

      # Check if include_context is valid (if provided)
      if request.include_context && !["none", "thisServer", "allServers"].includes?(request.include_context)
        return "Invalid includeContext: must be 'none', 'thisServer', or 'allServers'"
      end

      # All validations passed
      nil
    end

    # Handle a JSON-RPC request
    def handle(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # This method should not be called directly
      error_response(-32603, "SamplingHandler.handle called directly", id)
    end
  end
end
