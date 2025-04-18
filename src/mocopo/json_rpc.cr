require "./types"

module MocoPo
  # Base class for all JSON-RPC messages
  abstract class JsonRpcMessage
    # JSON-RPC version
    property jsonrpc : String = "2.0"

    # Convert to JSON-compatible Hash
    abstract def to_json_object : JsonObject
  end

  # Base class for all JSON-RPC responses
  abstract class JsonRpcResponse < JsonRpcMessage
    # Request ID
    property id : JsonRpcId

    # Initialize a new JSON-RPC response
    def initialize(@id = nil)
    end
  end

  # JSON-RPC success response
  class JsonRpcSuccessResponse < JsonRpcResponse
    # Response result
    property result : JsonRpcResult

    # Initialize a new success response
    def initialize(@result, id : JsonRpcId = nil)
      super(id)
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      result = {
        "jsonrpc" => @jsonrpc,
        "id"      => @id,
        "result"  => @result,
      } of String => JsonValue

      result
    end
  end

  # JSON-RPC error object
  class JsonRpcError
    # Error code
    property code : Int32

    # Error message
    property message : String

    # Additional error data
    property data : JsonRpcErrorData

    # Initialize a new JSON-RPC error
    def initialize(@code, @message, @data = nil)
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      result = {
        "code"    => @code,
        "message" => @message,
      } of String => JsonValue

      result["data"] = @data if @data

      result
    end
  end

  # JSON-RPC error response
  class JsonRpcErrorResponse < JsonRpcResponse
    # Error object
    property error : JsonRpcError

    # Initialize a new error response
    def initialize(@error, id : JsonRpcId = nil)
      super(id)
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      {
        "jsonrpc" => @jsonrpc,
        "id"      => @id,
        "error"   => @error.to_json_object,
      } of String => JsonValue
    end
  end

  # JSON-RPC notification
  class JsonRpcNotification < JsonRpcMessage
    # Notification method
    property method : String

    # Notification parameters
    property params : JsonRpcNotificationParams

    # Initialize a new notification
    def initialize(@method, @params = nil)
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      result = {
        "jsonrpc" => @jsonrpc,
        "method"  => @method,
      } of String => JsonValue

      result["params"] = @params if @params

      result
    end
  end

  # JSON-RPC request
  class JsonRpcRequest < JsonRpcMessage
    # Request ID
    property id : JsonRpcId

    # Request method
    property method : String

    # Request parameters
    property params : JsonRpcParams

    # Initialize a new request
    def initialize(@method, @id = nil, @params = nil)
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      result = {
        "jsonrpc" => @jsonrpc,
        "id"      => @id,
        "method"  => @method,
      } of String => JsonValue

      result["params"] = @params if @params

      result
    end
  end
end
