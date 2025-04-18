module MocoPo
  # Represents an argument for a tool
  class Argument
    # Argument name
    getter name : String

    # Argument type
    getter type : String

    # Whether the argument is required
    getter required : Bool

    # Human-readable description
    getter description : String?

    # Nested arguments (for object arguments)
    getter nested_arguments : Array(Argument)?

    # Item type (for array arguments)
    getter item_type : String?

    # Initialize a new argument
    def initialize(@name : String, @type : String, @required : Bool = false, @description : String? = nil, @nested_arguments : Array(Argument)? = nil, @item_type : String? = nil)
    end

    # Convert to JSON Schema
    def to_json_schema : Hash(String, JSON::Any)
      schema = {
        "type" => JSON::Any.new(@type),
      } of String => JSON::Any

      # Add description if present
      schema["description"] = JSON::Any.new(@description) if @description

      # Add item type for arrays
      if @type == "array" && @item_type
        schema["items"] = JSON::Any.new({"type" => JSON::Any.new(@item_type)} of String => JSON::Any)
      end

      # Add nested properties for objects
      if @type == "object" && @nested_arguments
        properties = {} of String => JSON::Any
        required = [] of JSON::Any

        @nested_arguments.not_nil!.each do |arg|
          properties[arg.name] = JSON::Any.new(arg.to_json_schema)
          required << JSON::Any.new(arg.name) if arg.required
        end

        schema["properties"] = JSON::Any.new(properties)
        schema["required"] = JSON::Any.new(required) unless required.empty?
      end

      schema
    end
  end

  # Builder for creating argument definitions
  class ArgumentBuilder
    # Arguments being built
    getter arguments : Array(Argument)

    # Initialize a new argument builder
    def initialize
      @arguments = [] of Argument
    end

    # Add a string argument
    def string(name : String, required : Bool = false, description : String? = nil) : Argument
      arg = Argument.new(name, "string", required, description)
      @arguments << arg
      arg
    end

    # Add a number argument
    def number(name : String, required : Bool = false, description : String? = nil) : Argument
      arg = Argument.new(name, "number", required, description)
      @arguments << arg
      arg
    end

    # Add a boolean argument
    def boolean(name : String, required : Bool = false, description : String? = nil) : Argument
      arg = Argument.new(name, "boolean", required, description)
      @arguments << arg
      arg
    end

    # Add an object argument
    def object(name : String, required : Bool = false, description : String? = nil, &block) : Argument
      # Create a nested builder
      nested_builder = ArgumentBuilder.new

      # Call the block with the nested builder
      yield nested_builder

      # Create the argument with nested arguments
      arg = Argument.new(name, "object", required, description, nested_builder.arguments)
      @arguments << arg
      arg
    end

    # Add an array argument
    def array(name : String, item_type : String, required : Bool = false, description : String? = nil) : Argument
      arg = Argument.new(name, "array", required, description, nil, item_type)
      @arguments << arg
      arg
    end

    # Build JSON Schema from arguments
    def to_json_schema : Hash(String, JSON::Any)
      properties = {} of String => JSON::Any
      required = [] of JSON::Any

      @arguments.each do |arg|
        properties[arg.name] = JSON::Any.new(arg.to_json_schema)
        required << JSON::Any.new(arg.name) if arg.required
      end

      schema = {
        "type"       => JSON::Any.new("object"),
        "properties" => JSON::Any.new(properties),
      } of String => JSON::Any

      schema["required"] = JSON::Any.new(required) unless required.empty?

      schema
    end
  end
end
