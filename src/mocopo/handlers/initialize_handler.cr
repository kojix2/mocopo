module MocoPo
  # Handler for initialize method
  class InitializeHandler < BaseHandler
    # Handle initialize request
    def handle(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract client protocol version
      client_protocol_version = get_string_param(params, "protocolVersion") || "unknown"

      # Check if we support the requested protocol version
      if client_protocol_version != PROTOCOL_VERSION
        # We could negotiate a different version here if needed
        # For now, we just return our supported version
      end

      # Build response
      result = {
        "protocolVersion" => PROTOCOL_VERSION,
        "capabilities"    => {
          "resources" => {
            "listChanged" => true,
          },
          "tools" => {
            "listChanged" => true,
          },
          "prompts" => {
            "listChanged" => true,
          },
          "sampling" => {} of String => Bool,
          "logging"  => {} of String => Bool,
        },
        "serverInfo" => {
          "name"    => @server.name,
          "version" => @server.version,
        },
      }

      # Return success response with automatic conversion to JsonValue
      safe_success_response(id, result)
    end
  end
end
