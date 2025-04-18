module MocoPo
  # Base class for message content
  abstract class MessageContent
    # Convert to JSON-compatible Hash
    abstract def to_json_object
  end

  # Text content for messages
  class TextContent < MessageContent
    # Text content
    getter text : String

    # Initialize a new text content
    def initialize(@text : String)
    end

    # Convert to JSON-compatible Hash
    def to_json_object
      {
        "type" => "text",
        "text" => @text,
      } of String => String | Hash(String, String | Nil)
    end
  end

  # Image content for messages
  class ImageContent < MessageContent
    # Base64 encoded image data
    getter data : String

    # MIME type of the image
    getter mime_type : String

    # Initialize a new image content
    def initialize(@data : String, @mime_type : String)
    end

    # Convert to JSON-compatible Hash
    def to_json_object
      {
        "type"     => "image",
        "data"     => @data,
        "mimeType" => @mime_type,
      } of String => String | Hash(String, String | Nil)
    end
  end

  # Resource content for messages
  class ResourceContentRef < MessageContent
    # Resource URI
    getter uri : String

    # Resource content
    getter resource : ResourceContent

    # Initialize a new resource content reference
    def initialize(@uri : String, @resource : ResourceContent)
    end

    # Convert to JSON-compatible Hash
    def to_json_object
      {
        "type"     => "resource",
        "resource" => @resource.to_json_object,
      } of String => String | Hash(String, String | Nil)
    end
  end

  # Prompt message
  class PromptMessage
    # Role of the message sender (user or assistant)
    getter role : String

    # Content of the message
    getter content : MessageContent

    # Initialize a new prompt message
    def initialize(@role : String, @content : MessageContent)
    end

    # Convert to JSON-compatible Hash
    def to_json_object
      {
        "role"    => @role,
        "content" => @content.to_json_object,
      } of String => String | Hash(String, String | Hash(String, String | Nil))
    end
  end

  # Prompt argument
  class PromptArgument
    # Argument name
    getter name : String

    # Whether the argument is required
    getter required : Bool

    # Human-readable description
    getter description : String?

    # Initialize a new prompt argument
    def initialize(@name : String, @required : Bool = false, @description : String? = nil)
    end

    # Convert to JSON-compatible Hash
    def to_json_object
      result = {
        "name"     => @name,
        "required" => @required,
      } of String => String | Bool | Nil

      result["description"] = @description if @description

      result
    end
  end

  # Represents a prompt that provides structured messages for LLMs
  class Prompt
    # Prompt name (unique identifier)
    getter name : String

    # Human-readable description
    getter description : String?

    # Arguments for customization
    getter arguments : Array(PromptArgument)

    # Execution callback
    @callback : Proc(Hash(String, JSON::Any)?, Array(PromptMessage))?

    # Initialize a new prompt
    def initialize(@name : String, @description : String? = nil, &callback : Hash(String, JSON::Any)? -> Array(PromptMessage))
      @arguments = [] of PromptArgument
      @callback = callback
    end

    # Initialize a new prompt without callback
    def initialize(@name : String, @description : String? = nil)
      @arguments = [] of PromptArgument
      @callback = nil
    end

    # Set the execution callback
    def on_execute(&callback : Hash(String, JSON::Any)? -> Array(PromptMessage))
      @callback = callback
      self
    end

    # Add an argument
    def add_argument(name : String, required : Bool = false, description : String? = nil) : Prompt
      @arguments << PromptArgument.new(name, required, description)
      self
    end

    # Execute the prompt with the given arguments
    def execute(arguments : Hash(String, JSON::Any)?) : Array(PromptMessage)
      if @callback
        @callback.not_nil!.call(arguments)
      else
        # Default response if no callback is set
        [
          PromptMessage.new(
            "user",
            TextContent.new("Prompt execution not implemented for: #{@name}")
          ),
        ]
      end
    end

    # Convert to JSON-compatible Hash
    def to_json_object
      result = {
        "name" => @name,
      } of String => String | Array(Hash(String, String | Bool | Nil)) | Nil

      result["description"] = @description

      unless @arguments.empty?
        args = @arguments.map(&.to_json_object)
        result["arguments"] = args
      end

      result
    end
  end

  # Manages prompts for an MCP server
  class PromptManager
    # Initialize a new prompt manager
    def initialize
      @prompts = {} of String => Prompt
    end

    # Register a new prompt
    def register(prompt : Prompt)
      @prompts[prompt.name] = prompt
    end

    # Get a prompt by name
    def get(name : String) : Prompt?
      @prompts[name]?
    end

    # List all registered prompts
    def list : Array(Prompt)
      @prompts.values
    end

    # Check if a prompt exists
    def exists?(name : String) : Bool
      @prompts.has_key?(name)
    end

    # Remove a prompt
    def remove(name : String)
      @prompts.delete(name)
    end
  end
end
