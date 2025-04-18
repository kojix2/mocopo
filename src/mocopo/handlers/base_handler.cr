module MocoPo
  # Base class for all JSON-RPC method handlers
  abstract class BaseHandler
    # Server instance
    @server : Server

    # Initialize a new handler
    def initialize(@server : Server)
    end

    # Handle a JSON-RPC request
    abstract def handle(id : JsonRpcId, params : JsonRpcParams) : JsonObject

    # Create a JSON-RPC success response
    protected def success_response(id : JsonRpcId, result : JsonRpcResult)
      JsonRpcSuccessResponse.new(result, id).to_json_object
    end

    # Create a JSON-RPC error response
    protected def error_response(code : Int32, message : String, id : JsonRpcId = nil)
      JsonRpcErrorResponse.new(JsonRpcError.new(code, message), id).to_json_object
    end
  end
end
