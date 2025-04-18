module MocoPo
  # Type aliases for common types

  # Basic JSON value types
  alias JsonPrimitive = String | Int32 | Float64 | Bool | Nil

  # Forward declaration for JsonObject and JsonArray
  alias JsonValue = JsonPrimitive | Hash(String, JsonValue) | Array(JsonValue)

  # JSON object type
  alias JsonObject = Hash(String, JsonValue)

  # JSON array type
  alias JsonArray = Array(JsonValue)

  # JSON-RPC ID type
  alias JsonRpcId = Int32 | String | Nil

  # JSON-RPC result type
  alias JsonRpcResult = JsonValue

  # JSON-RPC params type
  alias JsonRpcParams = JsonObject | Nil

  # JSON-RPC notification params type
  alias JsonRpcNotificationParams = JsonObject | Nil

  # JSON-RPC error data type
  alias JsonRpcErrorData = JsonValue | Nil
end
