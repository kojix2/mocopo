module MocoPo
  # Represents a resource that provides context to language models
  class Resource
    # Resource URI (unique identifier)
    getter uri : String

    # Human-readable name
    getter name : String

    # Optional description
    getter description : String?

    # Optional MIME type
    getter mime_type : String?

    # Optional size in bytes
    getter size : Int64?

    # Content callback
    @content_callback : Proc(Context?, ResourceContent)?

    # Initialize a new resource
    def initialize(@uri : String, @name : String, @description : String? = nil, @mime_type : String? = nil, @size : Int64? = nil, &content_callback : Context? -> ResourceContent)
      @content_callback = content_callback
    end

    # Initialize a new resource without content callback
    def initialize(@uri : String, @name : String, @description : String? = nil, @mime_type : String? = nil, @size : Int64? = nil)
      @content_callback = nil
    end

    # Set the content callback
    def on_read(&content_callback : Context? -> ResourceContent)
      @content_callback = content_callback
      self
    end

    # Get the resource content
    def get_content(context : Context? = nil) : ResourceContent
      if @content_callback
        @content_callback.not_nil!.call(context)
      else
        # Default content if no callback is set
        ResourceContent.text(
          uri: @uri,
          text: "Resource content not implemented for: #{@uri}",
          mime_type: @mime_type || "text/plain"
        )
      end
    end

    # Convert to JSON-compatible Hash
    def to_json_object
      result = {
        "uri"  => @uri,
        "name" => @name,
      } of String => String | Int64 | Nil

      result["description"] = @description
      result["mimeType"] = @mime_type
      result["size"] = @size

      # Remove nil values
      result.reject! { |_, v| v.nil? }

      result
    end
  end

  # Represents resource content
  class ResourceContent
    # Resource URI
    getter uri : String

    # MIME type
    getter mime_type : String?

    # Text content (if text resource)
    getter text : String?

    # Binary content (if binary resource)
    getter blob : String?

    # Initialize a new text resource content
    def self.text(uri : String, text : String, mime_type : String? = nil)
      new(uri, mime_type, text, nil)
    end

    # Initialize a new binary resource content
    def self.binary(uri : String, blob : String, mime_type : String? = nil)
      new(uri, mime_type, nil, blob)
    end

    # Initialize a new resource content
    def initialize(@uri : String, @mime_type : String?, @text : String?, @blob : String?)
    end

    # Convert to JSON-compatible Hash
    def to_json_object
      result = {"uri" => @uri} of String => String | Nil

      result["mimeType"] = @mime_type
      result["text"] = @text
      result["blob"] = @blob

      # Remove nil values
      result.reject! { |_, v| v.nil? }

      result
    end
  end

  # Manages resources for an MCP server
  class ResourceManager
    # Initialize a new resource manager
    def initialize
      @resources = {} of String => Resource
      @subscribers = {} of String => Set(String)
    end

    # Register a new resource
    def register(resource : Resource)
      @resources[resource.uri] = resource
    end

    # Get a resource by URI
    def get(uri : String) : Resource?
      @resources[uri]?
    end

    # List all registered resources
    def list : Array(Resource)
      @resources.values
    end

    # Check if a resource exists
    def exists?(uri : String) : Bool
      @resources.has_key?(uri)
    end

    # Remove a resource
    def remove(uri : String)
      @resources.delete(uri)
    end

    # Subscribe to a resource
    def subscribe(uri : String, subscriber_id : String)
      @subscribers[uri] ||= Set(String).new
      @subscribers[uri].add(subscriber_id)
    end

    # Unsubscribe from a resource
    def unsubscribe(uri : String, subscriber_id : String)
      return unless @subscribers[uri]?
      @subscribers[uri].delete(subscriber_id)
    end

    # Get subscribers for a resource
    def subscribers(uri : String) : Set(String)
      @subscribers[uri]? || Set(String).new
    end
  end
end
