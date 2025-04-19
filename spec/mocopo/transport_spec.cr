require "../spec_helper"

module MocoPo
  describe Transport do
    it "can be initialized" do
      transport = TestTransport.new
      transport.should be_a(Transport)
    end

    it "can set and call message handler" do
      transport = TestTransport.new
      message_received = false
      received_message = nil

      transport.on_message = ->(message : JsonObject) {
        message_received = true
        received_message = message
        nil
      }

      params = {} of String => JsonValue
      params["foo"] = "bar"

      test_message = {} of String => JsonValue
      test_message["method"] = "test"
      test_message["params"] = params

      transport.simulate_message(test_message)

      message_received.should be_true
      received_message.should eq(test_message)
    end

    it "can set and call error handler" do
      transport = TestTransport.new
      error_received = false
      received_error = nil

      transport.on_error = ->(error : Exception) {
        error_received = true
        received_error = error
        nil
      }

      test_error = Exception.new("Test error")
      transport.simulate_error(test_error)

      error_received.should be_true
      received_error.should eq(test_error)
    end

    it "can set and call close handler" do
      transport = TestTransport.new
      close_received = false

      transport.on_close = -> {
        close_received = true
        nil
      }

      transport.simulate_close

      close_received.should be_true
    end

    it "can start the transport" do
      transport = TestTransport.new
      transport.start
      transport.started.should be_true
    end

    it "can send messages" do
      transport = TestTransport.new

      params = {} of String => JsonValue
      params["foo"] = "bar"

      message = {} of String => JsonValue
      message["method"] = "test"
      message["params"] = params

      transport.send(message)
      transport.sent_messages.should contain(message)
    end

    it "can close the transport" do
      transport = TestTransport.new
      transport.close
      transport.closed.should be_true
    end
  end
end
