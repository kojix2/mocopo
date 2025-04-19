module MocoPo
  # Utility functions for MocoPo
  module Utils
    # Convert JsonValue to JSON::Any
    def self.to_json_any(value : JsonValue) : JSON::Any
      case value
      when String
        JSON::Any.new(value)
      when Int32
        JSON::Any.new(value)
      when Float64
        JSON::Any.new(value)
      when Bool
        JSON::Any.new(value)
      when Nil
        JSON::Any.new(nil)
      when Hash
        hash = {} of String => JSON::Any
        value.as(Hash).each do |k, v|
          hash[k.to_s] = to_json_any(v)
        end
        JSON::Any.new(hash)
      when Array
        array = [] of JSON::Any
        value.as(Array).each do |v|
          array << to_json_any(v)
        end
        JSON::Any.new(array)
      else
        JSON::Any.new(nil)
      end
    end

    # Convert JSON::Any to JsonValue
    def self.to_json_value(value : JSON::Any) : JsonValue
      raw = value.raw
      case raw
      when String, Int32, Float64, Bool, Nil
        raw
      when Hash
        hash = {} of String => JsonValue
        raw.as(Hash).each do |k, v|
          # Recursively convert each value
          case v
          when String, Int32, Float64, Bool, Nil
            hash[k.to_s] = v
          when Hash, Array
            # For complex types, convert to JSON string and parse back
            v_str = v.to_json
            v_json = JSON.parse(v_str)
            hash[k.to_s] = to_json_value(v_json)
          else
            hash[k.to_s] = nil
          end
        end
        hash
      when Array
        array = [] of JsonValue
        raw.as(Array).each do |v|
          # Recursively convert each value
          case v
          when String, Int32, Float64, Bool, Nil
            array << v
          when Hash, Array
            # For complex types, convert to JSON string and parse back
            v_str = v.to_json
            v_json = JSON.parse(v_str)
            array << to_json_value(v_json)
          else
            array << nil
          end
        end
        array
      else
        nil
      end
    end

    # Ensure any object is converted to JsonValue
    def self.ensure_json_value(obj) : JsonValue
      case obj
      when String, Int32, Float64, Bool, Nil
        obj
      when Hash
        result = {} of String => JsonValue
        obj.each do |k, v|
          result[k.to_s] = ensure_json_value(v)
        end
        result
      when Array
        result = [] of JsonValue
        obj.each do |v|
          result << ensure_json_value(v)
        end
        result
      else
        obj.to_s
      end
    end

    # Extract a string parameter from JsonRpcParams
    def self.get_string_param(params : JsonRpcParams?, key : String) : String?
      return nil unless params && params[key]?

      value = params[key]
      value.is_a?(String) ? value : nil
    end

    # Extract a hash parameter from JsonRpcParams
    def self.get_hash_param(params : JsonRpcParams?, key : String) : Hash(String, JsonValue)?
      return nil unless params && params[key]?

      value = params[key]
      value.is_a?(Hash) ? value.as(Hash(String, JsonValue)) : nil
    end

    # Extract an array parameter from JsonRpcParams
    def self.get_array_param(params : JsonRpcParams?, key : String) : Array(JsonValue)?
      return nil unless params && params[key]?

      value = params[key]
      value.is_a?(Array) ? value.as(Array(JsonValue)) : nil
    end
  end
end
