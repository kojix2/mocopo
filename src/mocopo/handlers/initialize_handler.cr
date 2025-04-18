module MocoPo
  # Handler for initialize method
  class InitializeHandler < BaseHandler
    # Handle initialize request
    def handle(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Extract client protocol version
      client_protocol_version = params.try &.["protocolVersion"]?.try &.as_s || "unknown"

      # Check if we support the requested protocol version
      if client_protocol_version != PROTOCOL_VERSION
        # We could negotiate a different version here if needed
        # For now, we just return our supported version
      end

      # Return server capabilities and information
      success_response(id, {
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
      })
    end
  end
end
