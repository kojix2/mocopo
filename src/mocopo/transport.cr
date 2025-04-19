module MocoPo
  # Transport interface for MCP communication
  abstract class Transport
    # Event handler for when a message is received
    property on_message : Proc(JsonObject, Nil)?

    # Event handler for when an error occurs
    property on_error : Proc(Exception, Nil)?

    # Event handler for when the transport is closed
    property on_close : Proc(Nil)?

    # Initialize a new transport
    def initialize
      @on_message = nil
      @on_error = nil
      @on_close = nil
    end

    # Start the transport
    abstract def start : Nil

    # Send a JSON-RPC message
    abstract def send(message : JsonObject) : Nil

    # Close the transport
    abstract def close : Nil

    # Handle a received message
    protected def handle_message(message : JsonObject) : Nil
      if handler = @on_message
        handler.call(message)
      end
    end

    # Handle an error
    protected def handle_error(error : Exception) : Nil
      if handler = @on_error
        handler.call(error)
      end
    end

    # Handle transport close
    protected def handle_close : Nil
      if handler = @on_close
        handler.call
      end
    end
  end
end
