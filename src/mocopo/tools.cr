require "./arguments"

module MocoPo
  # Represents a tool that can be invoked by language models
  class Tool
    # Tool name (unique identifier)
    getter name : String

    # Human-readable description
    getter description : String

    # JSON Schema defining expected parameters
    getter input_schema : Hash(String, JSON::Any)

    # Argument builder
    getter argument_builder : ArgumentBuilder

    # Execution callback
    @callback : Proc(Hash(String, JSON::Any)?, Hash(String, String | Array(Hash(String, String))))?

    # Initialize a new tool
    def initialize(@name : String, @description : String, @input_schema : Hash(String, JSON::Any), &callback : Hash(String, JSON::Any)? -> Hash(String, String | Array(Hash(String, String))))
      @callback = callback
      @argument_builder = ArgumentBuilder.new
    end

    # Initialize a new tool without callback
    def initialize(@name : String, @description : String, @input_schema : Hash(String, JSON::Any))
      @callback = nil
      @argument_builder = ArgumentBuilder.new
    end

    # Set the execution callback
    def on_execute(&callback : Hash(String, JSON::Any)? -> Hash(String, String | Array(Hash(String, String))))
      @callback = callback
      self
    end

    # Add a string argument
    def argument_string(name : String, required : Bool = false, description : String? = nil) : Tool
      @argument_builder.string(name, required, description)
      update_input_schema
      self
    end

    # Add a number argument
    def argument_number(name : String, required : Bool = false, description : String? = nil) : Tool
      @argument_builder.number(name, required, description)
      update_input_schema
      self
    end

    # Add a boolean argument
    def argument_boolean(name : String, required : Bool = false, description : String? = nil) : Tool
      @argument_builder.boolean(name, required, description)
      update_input_schema
      self
    end

    # Add an object argument
    def argument_object(name : String, required : Bool = false, description : String? = nil, &block) : Tool
      @argument_builder.object(name, required, description) do |builder|
        yield builder
      end
      update_input_schema
      self
    end

    # Add an array argument
    def argument_array(name : String, item_type : String, required : Bool = false, description : String? = nil) : Tool
      @argument_builder.array(name, item_type, required, description)
      update_input_schema
      self
    end

    # Update the input schema from the argument builder
    private def update_input_schema
      @input_schema = @argument_builder.to_json_schema
    end

    # Execute the tool with the given arguments
    def execute(arguments : Hash(String, JSON::Any)?) : Hash(String, String | Array(Hash(String, String)))
      if @callback
        @callback.not_nil!.call(arguments)
      else
        # Default response if no callback is set
        {
          "content" => [
            {
              "type" => "text",
              "text" => "Tool execution not implemented for: #{@name}",
            },
          ] of Hash(String, String),
          "isError" => "false",
        }
      end
    end

    # Convert to JSON-compatible Hash
    def to_json_object
      {
        "name"        => @name,
        "description" => @description,
        "inputSchema" => @input_schema,
      } of String => String | Hash(String, JSON::Any)
    end
  end

  # Manages tools for an MCP server
  class ToolManager
    # Initialize a new tool manager
    def initialize
      @tools = {} of String => Tool
    end

    # Register a new tool
    def register(tool : Tool)
      @tools[tool.name] = tool
    end

    # Get a tool by name
    def get(name : String) : Tool?
      @tools[name]?
    end

    # List all registered tools
    def list : Array(Tool)
      @tools.values
    end

    # Check if a tool exists
    def exists?(name : String) : Bool
      @tools.has_key?(name)
    end

    # Remove a tool
    def remove(name : String)
      @tools.delete(name)
    end
  end
end
