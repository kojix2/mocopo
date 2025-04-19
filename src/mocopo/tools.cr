require "./arguments"

module MocoPo
  # Represents a tool that can be invoked by language models
  class Tool
    # Tool name (unique identifier)
    getter name : String

    # Human-readable description
    getter description : String

    # JSON Schema defining expected parameters
    getter input_schema : JsonObject

    # Argument builder
    getter argument_builder : ArgumentBuilder

    # Execution callback
    @callback : Proc(JsonObject?, Context?, Hash(String, String | Array(Hash(String, String))))?

    # List of allowed client IDs (for access control)
    property allowed_clients : Array(String)?

    # Initialize a new tool
    def initialize(@name : String, @description : String, @input_schema : JsonObject, &callback : (JsonObject?, Context?) -> Hash(String, String | Array(Hash(String, String))))
      @callback = callback
      @argument_builder = ArgumentBuilder.new
      @allowed_clients = nil
    end

    # Initialize a new tool without callback
    def initialize(@name : String, @description : String, @input_schema : JsonObject)
      @callback = nil
      @argument_builder = ArgumentBuilder.new
      @allowed_clients = nil
    end

    # Set the execution callback
    def on_execute(&callback : (JsonObject?, Context?) -> Hash(String, String | Array(Hash(String, String))))
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

    # Validate arguments against the input schema
    private def validate_arguments(arguments : JsonObject?) : Array(String)
      errors = [] of String
      schema = @input_schema

      # Only basic validation: type and required fields
      schema_type = schema["type"]?
      if schema_type.is_a?(String) && schema_type == "object"
        # Check required fields
        if schema["required"]? && schema["required"].is_a?(Array)
          required_fields = schema["required"].as(Array).map do |field|
            field.is_a?(String) ? field : field.to_s
          end
          required_fields.each do |key|
            unless arguments && arguments.has_key?(key)
              errors << "Missing required argument: #{key}"
            end
          end
        end

        # Type checking (string, number, boolean)
        if arguments && schema["properties"]? && schema["properties"].is_a?(Hash)
          properties = schema["properties"].as(Hash)
          arguments.each do |key, value|
            if properties.has_key?(key) && properties[key].is_a?(Hash)
              prop = properties[key].as(Hash)
              if prop["type"]?
                prop_type = prop["type"].is_a?(String) ? prop["type"].as(String) : prop["type"].to_s
                case prop_type
                when "string"
                  unless value.is_a?(String)
                    errors << "Argument '#{key}' must be a string"
                  end
                when "number"
                  unless value.is_a?(Int32) || value.is_a?(Float64)
                    errors << "Argument '#{key}' must be a number"
                  end
                when "boolean"
                  unless value.is_a?(Bool)
                    errors << "Argument '#{key}' must be a boolean"
                  end
                end
              end
            end
          end
        end
      end
      errors
    end

    # Execute the tool with the given arguments
    def execute(arguments : JsonObject?, context : Context? = nil) : Hash(String, String | Array(Hash(String, String)))
      # Access control: check allowed_clients if set
      if @allowed_clients && context
        unless @allowed_clients.not_nil!.includes?(context.client_id)
          return {
            "content" => [
              {
                "type" => "text",
                "text" => "Access denied: client_id '#{context.client_id}' is not authorized to use this tool.",
              },
            ] of Hash(String, String),
            "isError" => "true",
          }
        end
      end

      validation_errors = validate_arguments(arguments)
      if !validation_errors.empty?
        {
          "content" => [
            {
              "type" => "text",
              "text" => "Input validation error(s): " + validation_errors.join(", "),
            },
          ] of Hash(String, String),
          "isError" => "true",
        }
      elsif @callback
        # Sanitize output: HTML-escape all text fields in the result
        raw_result = @callback.not_nil!.call(arguments, context)
        if raw_result["content"]?.is_a?(Array)
          sanitized_content = raw_result["content"].as(Array(Hash(String, String))).map do |item|
            if item["type"]? == "text" && item["text"]?
              item = item.dup
              item["text"] = html_escape(item["text"])
            end
            item
          end
          raw_result["content"] = sanitized_content
        end
        raw_result
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

    # Simple HTML escape utility for output sanitization
    private def html_escape(text : String) : String
      text.gsub("&", "&amp;")
        .gsub("<", "&lt;")
        .gsub(">", "&gt;")
        .gsub("\"", "&quot;")
        .gsub("'", "&#39;")
    end

    # Convert to JSON-compatible Hash
    def to_json_object
      {
        "name"        => @name,
        "description" => @description,
        "inputSchema" => @input_schema,
      } of String => String | JsonObject
    end
  end

  # Manages tools for an MCP server
  class ToolManager
    # Server instance
    @server : Server?

    # Rate limiting: {client_id => [timestamps]}
    @rate_limit_log : Hash(String, Array(Time))

    # Rate limit settings
    RATE_LIMIT_WINDOW    = 10 # seconds
    RATE_LIMIT_MAX_CALLS =  5

    # Initialize a new tool manager
    def initialize
      @tools = {} of String => Tool
      @server = nil
      @rate_limit_log = {} of String => Array(Time)
    end

    # Execute a tool by name with rate limiting.
    # Returns an error if the tool is not found, or if the client exceeds the rate limit.
    # This method should be called by handlers to enforce security best practices.
    def execute_tool(name : String, arguments : JsonObject?, context : Context? = nil) : Hash(String, String | Array(Hash(String, String)))
      tool = @tools[name]?
      unless tool
        return {
          "content" => [
            {
              "type" => "text",
              "text" => "Tool not found: #{name}",
            },
          ] of Hash(String, String),
          "isError" => "true",
        }
      end

      # Rate limiting
      if context
        client_id = context.client_id
        now = Time.utc
        log = @rate_limit_log.has_key?(client_id) ? @rate_limit_log[client_id] : [] of Time
        # Remove old entries
        log = log.select { |t| (now - t).total_seconds < RATE_LIMIT_WINDOW }
        if log.size >= RATE_LIMIT_MAX_CALLS
          return {
            "content" => [
              {
                "type" => "text",
                "text" => "Rate limit exceeded: max #{RATE_LIMIT_MAX_CALLS} calls per #{RATE_LIMIT_WINDOW} seconds.",
              },
            ] of Hash(String, String),
            "isError" => "true",
          }
        end
        log << now
        @rate_limit_log[client_id] = log
      end

      tool.execute(arguments, context)
    end

    # Set the server instance
    def server=(server : Server)
      @server = server
    end

    # Register a new tool
    def register(tool : Tool)
      was_new = !@tools.has_key?(tool.name)
      @tools[tool.name] = tool

      # Notify clients if this is a new tool
      if was_new && (server = @server) && (notification_manager = server.notification_manager)
        notification_manager.tools_list_changed
      end
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
      if @tools.has_key?(name)
        @tools.delete(name)

        # Notify clients that a tool was removed
        if (server = @server) && (notification_manager = server.notification_manager)
          notification_manager.tools_list_changed
        end
      end
    end
  end
end
