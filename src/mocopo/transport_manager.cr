require "./transport"
require "./transports/http_transport"
require "./transports/stdio_transport"
require "./transports/sse_transport"

module MocoPo
  # Manager for MCP transports
  class TransportManager
    # Server instance
    @server : Server

    # Active transports
    @transports : Array(Transport)

    # Initialize a new transport manager
    def initialize(@server : Server)
      @transports = [] of Transport
    end

    # Register a transport
    def register(transport : Transport) : Transport
      # Set up message handler
      transport.on_message = ->(message : JsonObject) {
        handle_message(message, transport)
        nil
      }

      # Set up error handler
      transport.on_error = ->(error : Exception) {
        handle_error(error, transport)
        nil
      }

      # Set up close handler
      transport.on_close = -> {
        handle_close(transport)
        nil
      }

      # Add to active transports
      @transports << transport

      # Return the transport for further configuration
      transport
    end

    # Create and register an HTTP transport
    def create_http_transport : HttpTransport
      transport = HttpTransport.new(@server)
      register(transport)
      transport
    end

    # Create and register a stdio transport
    def create_stdio_transport : StdioTransport
      transport = StdioTransport.new
      register(transport)
      transport
    end

    # Create and register an SSE transport
    def create_sse_transport : SseTransport
      transport = SseTransport.new(@server)
      register(transport)
      transport
    end

    # Start all registered transports
    def start_all : Nil
      @transports.each(&.start)
    end

    # Close all registered transports
    def close_all : Nil
      @transports.each(&.close)
      @transports.clear
    end

    # Handle a message received from a transport
    private def handle_message(message : JsonObject, transport : Transport) : Nil
      # Process the message using the server's handler manager
      if handler_manager = @server.handler_manager
        # Check if it's a request or notification
        if message["id"]?
          # It's a request, process it and send the response
          method_value = message["method"]?
          method = if method_value.is_a?(String)
                     method_value
                   else
                     nil
                   end

          id = message["id"]?
          params = message["params"]?

          if method
            # Ensure id is a valid JsonRpcId (Int32, String, or Nil)
            id_value = case id
                       when Int32, String, Nil
                         id
                       else
                         nil
                       end

            # Ensure params is a valid JsonRpcParams (Hash(String, JsonValue) | Nil)
            params_value = case params
                           when Hash
                             params.as(Hash(String, JsonValue))
                           when Nil
                             nil
                           else
                             nil
                           end

            response = handler_manager.handle_request(method, id_value, params_value)
            transport.send(response)
          else
            # Invalid request
            # Ensure id is a valid JsonRpcId (Int32, String, or Nil)
            id_value = case id
                       when Int32, String, Nil
                         id
                       else
                         nil
                       end

            error = JsonRpcErrorResponse.new(
              JsonRpcError.new(-32600, "Invalid Request"),
              id_value
            ).to_json_object
            transport.send(error)
          end
        else
          # It's a notification, just process it
          method_value = message["method"]?
          method = if method_value.is_a?(String)
                     method_value
                   else
                     nil
                   end

          params = message["params"]?

          if method
            # Currently, notifications are not handled
            # This could be extended in the future
          end
        end
      end
    end

    # Handle an error from a transport
    private def handle_error(error : Exception, transport : Transport) : Nil
      # Log the error
      puts "Transport error: #{error.message}"
    end

    # Handle a transport close
    private def handle_close(transport : Transport) : Nil
      # Remove from active transports
      @transports.delete(transport)
    end
  end
end
