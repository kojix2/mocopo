require "kemal"
require "../transport"
require "../json_rpc"
require "../utils"

module MocoPo
  # HTTP transport implementation for MCP
  class HttpTransport < Transport
    # Server instance
    @server : Server

    # Initialize a new HTTP transport
    def initialize(@server : Server)
    end

    # Start the transport
    def start : Nil
      # Setup HTTP endpoint for JSON-RPC
      post "/mcp" do |env|
        begin
          # Parse JSON-RPC request
          request_body = env.request.body.try &.gets_to_end
          next error_response(400, "Missing request body").to_json unless request_body

          # Parse as JSON
          json = JSON.parse(request_body)

          # Convert to JsonObject
          json_object = {} of String => JsonValue
          json.as_h.each do |k, v|
            json_object[k.to_s] = Utils.to_json_value(v)
          end

          # Process the message
          handle_message(json_object)

          # Return JSON-RPC response
          env.response.headers["Content-Type"] = "application/json"
          response = process_jsonrpc(json_object)
          response.to_json
        rescue ex : JSON::ParseException
          env.response.status_code = 400
          next error_response(-32700, "Parse error: #{ex.message}").to_json
        rescue ex
          env.response.status_code = 500
          handle_error(ex)
          next error_response(-32603, "Internal error: #{ex.message}").to_json
        end
      end
    end

    # Send a JSON-RPC message
    def send(message : JsonObject) : Nil
      # In HTTP transport, responses are sent directly in the HTTP response
      # This method is primarily used for notifications or responses to requests
      # that were not part of the current HTTP request/response cycle
      puts "Sending message: #{message.to_json}"
    end

    # Close the transport
    def close : Nil
      # Stop the HTTP server
      Kemal.stop
      handle_close
    end

    # Process a JSON-RPC request and return a response
    private def process_jsonrpc(json : JsonObject) : JsonObject
      # Ensure it's a valid JSON-RPC 2.0 request
      return error_response(-32600, "Invalid Request") unless json["jsonrpc"]? == "2.0"

      # Extract request fields
      id_value = json["id"]?
      id = case id_value
           when Int32, String, Nil
             id_value
           else
             nil
           end

      method_value = json["method"]?
      method = if method_value.is_a?(String)
                 method_value
               else
                 nil
               end

      params_value = json["params"]?
      params = if params_value.is_a?(Hash)
                 params_value.as(Hash(String, JsonValue))
               else
                 nil
               end

      # Handle method not found
      return error_response(-32601, "Method not found", id) unless method

      # Process using handler manager if available
      if handler_manager = @server.handler_manager
        handler_manager.handle_request(method, id, params)
      else
        # Fallback to error response if handler manager is not available
        error_response(-32603, "Handler manager not initialized", id)
      end
    end

    # Create a JSON-RPC error response
    private def error_response(code : Int32, message : String, id : JsonRpcId = nil) : JsonObject
      JsonRpcErrorResponse.new(JsonRpcError.new(code, message), id).to_json_object
    end
  end
end
