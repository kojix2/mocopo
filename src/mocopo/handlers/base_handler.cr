module MocoPo
  # Base class for all JSON-RPC method handlers
  abstract class BaseHandler
    # Server instance
    @server : Server

    # Initialize a new handler
    def initialize(@server : Server)
    end

    # Handle a JSON-RPC request
    abstract def handle(id, params) : Hash(String, JSON::Any | Array(JSON::Any) | Hash(String, JSON::Any) | String | Int32 | Bool | Nil)

    # Create a JSON-RPC success response
    protected def success_response(id, result)
      {
        "jsonrpc" => "2.0",
        "id"      => id,
        "result"  => result,
      }
    end

    # Create a JSON-RPC error response
    protected def error_response(code : Int32, message : String, id = nil)
      {
        "jsonrpc" => "2.0",
        "id"      => id,
        "error"   => {
          "code"    => code,
          "message" => message,
        },
      }
    end
  end
end
