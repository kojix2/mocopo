require "../utils"

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

    # Create a JSON-RPC success response with automatic conversion to JsonValue
    protected def safe_success_response(id : JsonRpcId, result)
      json_result = Utils.ensure_json_value(result)
      success_response(id, json_result)
    end

    # Create a JSON-RPC error response
    protected def error_response(code : Int32, message : String, id : JsonRpcId = nil)
      JsonRpcErrorResponse.new(JsonRpcError.new(code, message), id).to_json_object
    end

    # Extract a string parameter from JsonRpcParams
    protected def get_string_param(params : JsonRpcParams?, key : String) : String?
      Utils.get_string_param(params, key)
    end

    # Extract a hash parameter from JsonRpcParams
    protected def get_hash_param(params : JsonRpcParams?, key : String) : Hash(String, JsonValue)?
      Utils.get_hash_param(params, key)
    end

    # Extract an array parameter from JsonRpcParams
    protected def get_array_param(params : JsonRpcParams?, key : String) : Array(JsonValue)?
      Utils.get_array_param(params, key)
    end

    # Convert Hash(String, JSON::Any) to Hash(String, JsonValue)
    protected def json_any_to_json_value(hash : Hash(String, JSON::Any)?) : Hash(String, JsonValue)?
      return nil unless hash

      result = {} of String => JsonValue
      hash.each do |k, v|
        result[k] = Utils.to_json_value(v)
      end
      result
    end

    # Convert JsonValue to JSON::Any
    protected def json_value_to_json_any(value : JsonValue) : JSON::Any
      Utils.to_json_any(value)
    end
  end
end
