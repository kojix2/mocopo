require "../transport"
require "../json_rpc"
require "../utils"
require "json"

module MocoPo
  # Standard input/output transport implementation for MCP
  class StdioTransport < Transport
    # Flag to indicate if the transport is running
    @running : Bool = false

    # Initialize a new stdio transport
    def initialize
      super()
    end

    # Start the transport
    def start : Nil
      return if @running

      @running = true

      # Start a fiber to read from stdin
      spawn do
        begin
          while @running
            # Read a line from stdin
            line = STDIN.gets

            # Break if EOF or nil
            break unless line

            # Skip empty lines
            next if line.empty?

            begin
              # Parse JSON-RPC message
              json = JSON.parse(line)

              # Convert to JsonObject
              json_object = {} of String => JsonValue
              json.as_h.each do |k, v|
                json_object[k.to_s] = Utils.to_json_value(v)
              end

              # Handle the message
              handle_message(json_object)
            rescue ex : JSON::ParseException
              # Handle parse error
              error = JsonRpcErrorResponse.new(
                JsonRpcError.new(-32700, "Parse error: #{ex.message}"),
                nil
              ).to_json_object
              send(error)
              handle_error(ex)
            rescue ex
              # Handle other errors
              error = JsonRpcErrorResponse.new(
                JsonRpcError.new(-32603, "Internal error: #{ex.message}"),
                nil
              ).to_json_object
              send(error)
              handle_error(ex)
            end
          end
        rescue ex
          handle_error(ex)
        ensure
          @running = false
          handle_close
        end
      end
    end

    # Send a JSON-RPC message
    def send(message : JsonObject) : Nil
      # Write the message to stdout - only JSON, no additional text
      STDOUT.puts(message.to_json)
      STDOUT.flush
    end

    # Close the transport
    def close : Nil
      @running = false
      handle_close
    end
  end
end
