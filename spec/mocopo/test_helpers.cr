module MocoPo
  # Test implementation of the abstract Transport class for testing
  class TestTransport < Transport
    getter started : Bool = false
    getter closed : Bool = false
    getter sent_messages : Array(JsonObject) = [] of JsonObject

    def start : Nil
      @started = true
    end

    def send(message : JsonObject) : Nil
      @sent_messages << message
    end

    def close : Nil
      @closed = true
    end

    # Helper method to simulate receiving a message
    def simulate_message(message : JsonObject) : Nil
      handle_message(message)
    end

    # Helper method to simulate an error
    def simulate_error(error : Exception) : Nil
      handle_error(error)
    end

    # Helper method to simulate closing
    def simulate_close : Nil
      handle_close
    end
  end
end
