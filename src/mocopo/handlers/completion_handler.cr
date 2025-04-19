module MocoPo
  # Handler for completion methods
  class CompletionHandler < BaseHandler
    # Rate limiting: {client_id => [timestamps]}
    @rate_limit_log : Hash(String, Array(Time))

    # Rate limit settings
    RATE_LIMIT_WINDOW    =  5 # seconds
    RATE_LIMIT_MAX_CALLS = 10 # maximum calls per window

    # Initialize a new completion handler
    def initialize(server : Server)
      super(server)
      @rate_limit_log = {} of String => Array(Time)
    end

    # Handle completion/complete request
    def handle_complete(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract reference and argument using helper methods
      ref_json = get_hash_param(params, "ref")
      arg_json = get_hash_param(params, "argument")

      # Validate parameters
      unless ref_json && arg_json
        return error_response(-32602, "Missing required parameters: ref and argument", id)
      end

      # Parse reference
      ref = Completion::Reference.from_json(ref_json)
      unless ref
        return error_response(-32602, "Invalid reference", id)
      end

      # Parse argument
      arg = Completion::Argument.from_json(arg_json)
      unless arg
        return error_response(-32602, "Invalid argument", id)
      end

      # Create a context for the completion
      request_id = id.to_s
      client_id = "client-#{Random.new.hex(4)}" # In a real implementation, this would be tied to the client
      context = Context.new(request_id, client_id, @server)

      # Apply rate limiting
      if exceeds_rate_limit?(client_id)
        return error_response(-32603, "Rate limit exceeded", id)
      end

      # Get completion result
      result = Completion.complete(ref, arg, @server)

      # Build response with explicit type
      response = {} of String => JsonValue

      # Convert result.to_json_object to JsonValue
      result_json = result.to_json_object
      result_json_str = result_json.to_json
      result_json_value = JSON.parse(result_json_str)

      response["completion"] = Utils.to_json_value(result_json_value)

      # Return the completion result
      success_response(id, response)
    end

    # Handle a JSON-RPC request
    def handle(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # This method should not be called directly
      error_response(-32603, "CompletionHandler.handle called directly", id)
    end

    # Check if the client exceeds the rate limit
    private def exceeds_rate_limit?(client_id : String) : Bool
      now = Time.utc
      log = @rate_limit_log.has_key?(client_id) ? @rate_limit_log[client_id] : [] of Time

      # Remove old entries
      log = log.select { |t| (now - t).total_seconds < RATE_LIMIT_WINDOW }

      # Check if the rate limit is exceeded
      if log.size >= RATE_LIMIT_MAX_CALLS
        return true
      end

      # Add the current timestamp
      log << now
      @rate_limit_log[client_id] = log

      false
    end
  end
end
