require "../spec_helper"

module MocoPo
  # Test server for testing
  class TestServer < Server
    def initialize
      super("TestServer", "1.0.0", setup_routes: false, setup_transports: false)
    end
  end

  # Test transport for testing
  class TestManagerTransport < Transport
    property started : Bool = false
    property closed : Bool = false
    property sent_messages : Array(JsonObject) = [] of JsonObject
    property message_handler_called : Bool = false
    property error_handler_called : Bool = false
    property close_handler_called : Bool = false

    def start : Nil
      @started = true
    end

    def send(message : JsonObject) : Nil
      @sent_messages << message
    end

    def close : Nil
      @closed = true
    end

    # Helper methods to simulate events
    def simulate_message(message : JsonObject) : Nil
      if handler = @on_message
        @message_handler_called = true
        handler.call(message)
      end
    end

    def simulate_error(error : Exception) : Nil
      if handler = @on_error
        @error_handler_called = true
        handler.call(error)
      end
    end

    def simulate_close : Nil
      if handler = @on_close
        @close_handler_called = true
        handler.call
      end
    end
  end
end
