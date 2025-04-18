require "json"

module MocoPo
  # Type aliases for sampling
  alias SamplingMetadata = Hash(String, String)
  alias SamplingStopSequences = Array(String)

  # Content type for messages
  enum ContentType
    Text
    Image
    Audio
  end

  # Helper methods for JSON parsing
  def self.safe_string(value : JsonValue?) : String?
    return nil if value.nil?

    case value
    when String
      value.as(String)
    else
      begin
        value.to_s
      rescue
        nil
      end
    end
  end

  def self.safe_float(value : JsonValue?) : Float64?
    return nil if value.nil?

    case value
    when Float64
      value.as(Float64)
    when Int32
      value.as(Int32).to_f64
    else
      begin
        value.to_s.to_f64
      rescue
        nil
      end
    end
  end

  def self.safe_int(value : JsonValue?) : Int32?
    return nil if value.nil?

    case value
    when Int32
      value.as(Int32)
    when Float64
      value.as(Float64).to_i32
    else
      begin
        value.to_s.to_i32
      rescue
        nil
      end
    end
  end

  def self.safe_hash(value : JsonValue?) : JsonObject?
    return nil if value.nil?

    case value
    when Hash
      value.as(JsonObject)
    else
      nil
    end
  end

  def self.safe_array(value : JsonValue?) : Array(JsonValue)?
    return nil if value.nil?

    case value
    when Array
      value.as(Array(JsonValue))
    else
      nil
    end
  end

  # Message content class for sampling
  class SamplingMessageContent
    # Content type
    property type : String

    # Text content (for text type)
    property text : String?

    # Binary data (for image/audio types, base64 encoded)
    property data : String?

    # MIME type (for image/audio types)
    property mime_type : String?

    # Initialize a new message content
    def initialize(@type : String, @text : String? = nil, @data : String? = nil, @mime_type : String? = nil)
    end

    # Create a text content
    def self.text(text : String) : SamplingMessageContent
      new("text", text)
    end

    # Create an image content
    def self.image(data : String, mime_type : String) : SamplingMessageContent
      new("image", nil, data, mime_type)
    end

    # Create an audio content
    def self.audio(data : String, mime_type : String) : SamplingMessageContent
      new("audio", nil, data, mime_type)
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      result = {"type" => @type} of String => JsonValue

      case @type
      when "text"
        result["text"] = @text
      when "image", "audio"
        result["data"] = @data
        result["mimeType"] = @mime_type
      end

      result
    end

    # Create from JSON-compatible Hash
    def self.from_json_object(json : JsonObject) : SamplingMessageContent
      type = MocoPo.safe_string(json["type"]?) || "text"

      case type
      when "text"
        text = MocoPo.safe_string(json["text"]?) || ""
        SamplingMessageContent.text(text)
      when "image"
        data = MocoPo.safe_string(json["data"]?) || ""
        mime_type = MocoPo.safe_string(json["mimeType"]?) || "image/jpeg"
        SamplingMessageContent.image(data, mime_type)
      when "audio"
        data = MocoPo.safe_string(json["data"]?) || ""
        mime_type = MocoPo.safe_string(json["mimeType"]?) || "audio/wav"
        SamplingMessageContent.audio(data, mime_type)
      else
        SamplingMessageContent.text("")
      end
    rescue ex
      # Fallback to empty text content
      SamplingMessageContent.text("")
    end
  end

  # Message class for sampling
  class SamplingMessage
    # Role (user or assistant)
    property role : String

    # Content
    property content : SamplingMessageContent

    # Initialize a new message
    def initialize(@role : String, @content : SamplingMessageContent)
    end

    # Create a user message with text content
    def self.user_text(text : String) : SamplingMessage
      new("user", SamplingMessageContent.text(text))
    end

    # Create an assistant message with text content
    def self.assistant_text(text : String) : SamplingMessage
      new("assistant", SamplingMessageContent.text(text))
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      {
        "role"    => @role,
        "content" => @content.to_json_object,
      } of String => JsonValue
    end

    # Create from JSON-compatible Hash
    def self.from_json_object(json : JsonObject) : SamplingMessage
      role = MocoPo.safe_string(json["role"]?) || "user"

      content_json = MocoPo.safe_hash(json["content"]?) || {} of String => JsonValue
      content = SamplingMessageContent.from_json_object(content_json)

      new(role, content)
    rescue ex
      # Fallback to empty user message
      user_text("")
    end
  end

  # Model hint class
  class ModelHint
    # Model name
    property name : String

    # Initialize a new model hint
    def initialize(@name : String)
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      {
        "name" => @name,
      } of String => JsonValue
    end

    # Create from JSON-compatible Hash
    def self.from_json_object(json : JsonObject) : ModelHint
      name = MocoPo.safe_string(json["name"]?) || ""
      new(name)
    rescue ex
      # Fallback to empty name
      new("")
    end
  end

  # Model preferences class
  class ModelPreferences
    # Model hints
    property hints : Array(ModelHint)

    # Cost priority (0.0 to 1.0)
    property cost_priority : Float64?

    # Speed priority (0.0 to 1.0)
    property speed_priority : Float64?

    # Intelligence priority (0.0 to 1.0)
    property intelligence_priority : Float64?

    # Initialize a new model preferences
    def initialize(@hints = [] of ModelHint, @cost_priority = nil, @speed_priority = nil, @intelligence_priority = nil)
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      result = {} of String => JsonValue

      unless @hints.empty?
        hints_array = [] of JsonValue
        @hints.each do |hint|
          hints_array << hint.to_json_object
        end
        result["hints"] = hints_array
      end

      result["costPriority"] = @cost_priority if @cost_priority
      result["speedPriority"] = @speed_priority if @speed_priority
      result["intelligencePriority"] = @intelligence_priority if @intelligence_priority

      result
    end

    # Create from JSON-compatible Hash
    def self.from_json_object(json : JsonObject) : ModelPreferences
      hints = [] of ModelHint

      hints_array = MocoPo.safe_array(json["hints"]?)
      if hints_array
        hints = hints_array.compact_map do |hint_json|
          hint_hash = MocoPo.safe_hash(hint_json)
          hint_hash ? ModelHint.from_json_object(hint_hash) : nil
        end
      end

      cost_priority = MocoPo.safe_float(json["costPriority"]?)
      speed_priority = MocoPo.safe_float(json["speedPriority"]?)
      intelligence_priority = MocoPo.safe_float(json["intelligencePriority"]?)

      new(hints, cost_priority, speed_priority, intelligence_priority)
    rescue ex
      # Fallback to empty preferences
      new
    end
  end

  # Sampling request class
  class SamplingRequest
    # Messages
    property messages : Array(SamplingMessage)

    # Model preferences
    property model_preferences : ModelPreferences?

    # System prompt
    property system_prompt : String?

    # Include context
    property include_context : String?

    # Temperature
    property temperature : Float64?

    # Maximum tokens
    property max_tokens : Int32

    # Stop sequences
    property stop_sequences : SamplingStopSequences?

    # Metadata
    property metadata : SamplingMetadata?

    # Initialize a new sampling request
    def initialize(@messages = [] of SamplingMessage, @model_preferences = nil, @system_prompt = nil, @include_context = nil, @temperature = nil, @max_tokens = 100, @stop_sequences = nil, @metadata = nil)
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      result = {} of String => JsonValue

      # Add messages
      messages_array = [] of JsonValue
      @messages.each do |message|
        messages_array << message.to_json_object
      end
      result["messages"] = messages_array

      # Add maxTokens
      result["maxTokens"] = @max_tokens

      # Add optional fields
      result["modelPreferences"] = @model_preferences.not_nil!.to_json_object if @model_preferences
      result["systemPrompt"] = @system_prompt if @system_prompt
      result["includeContext"] = @include_context if @include_context
      result["temperature"] = @temperature if @temperature

      # Add stop sequences
      if @stop_sequences && !@stop_sequences.not_nil!.empty?
        stop_sequences_array = [] of JsonValue
        @stop_sequences.not_nil!.each do |seq|
          stop_sequences_array << seq
        end
        result["stopSequences"] = stop_sequences_array
      end

      # Add metadata
      if @metadata && !@metadata.not_nil!.empty?
        metadata_json = {} of String => JsonValue
        @metadata.not_nil!.each do |key, value|
          metadata_json[key] = value
        end
        result["metadata"] = metadata_json
      end

      result
    end

    # Create from JSON-compatible Hash
    def self.from_json_object(json : JsonObject) : SamplingRequest
      messages = [] of SamplingMessage

      messages_array = MocoPo.safe_array(json["messages"]?)
      if messages_array
        messages = messages_array.compact_map do |message_json|
          message_hash = MocoPo.safe_hash(message_json)
          message_hash ? SamplingMessage.from_json_object(message_hash) : nil
        end
      end

      model_preferences = nil
      model_prefs_hash = MocoPo.safe_hash(json["modelPreferences"]?)
      if model_prefs_hash
        model_preferences = ModelPreferences.from_json_object(model_prefs_hash)
      end

      system_prompt = MocoPo.safe_string(json["systemPrompt"]?)
      include_context = MocoPo.safe_string(json["includeContext"]?)
      temperature = MocoPo.safe_float(json["temperature"]?)
      max_tokens = MocoPo.safe_int(json["maxTokens"]?) || 100

      stop_sequences = nil
      stop_sequences_array = MocoPo.safe_array(json["stopSequences"]?)
      if stop_sequences_array
        stop_sequences = stop_sequences_array.compact_map { |seq| MocoPo.safe_string(seq) }
      end

      metadata = nil
      metadata_hash = MocoPo.safe_hash(json["metadata"]?)
      if metadata_hash
        metadata = {} of String => String
        metadata_hash.each do |key, value|
          if str_value = MocoPo.safe_string(value)
            metadata[key] = str_value
          end
        end
      end

      new(messages, model_preferences, system_prompt, include_context, temperature, max_tokens, stop_sequences, metadata)
    rescue ex
      # Fallback to default request
      new
    end
  end

  # Sampling response class
  class SamplingResponse
    # Role (usually "assistant")
    property role : String

    # Content
    property content : SamplingMessageContent

    # Model used
    property model : String

    # Stop reason
    property stop_reason : String?

    # Initialize a new sampling response
    def initialize(@role : String, @content : SamplingMessageContent, @model : String, @stop_reason = nil)
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      result = {} of String => JsonValue

      # Add required fields
      result["role"] = @role
      result["content"] = @content.to_json_object
      result["model"] = @model

      # Add optional fields
      result["stopReason"] = @stop_reason if @stop_reason

      result
    end

    # Create from JSON-compatible Hash
    def self.from_json_object(json : JsonObject) : SamplingResponse
      role = MocoPo.safe_string(json["role"]?) || "assistant"

      content_json = MocoPo.safe_hash(json["content"]?) || {} of String => JsonValue
      content = SamplingMessageContent.from_json_object(content_json)

      model = MocoPo.safe_string(json["model"]?) || "unknown"
      stop_reason = MocoPo.safe_string(json["stopReason"]?)

      new(role, content, model, stop_reason)
    rescue ex
      # Fallback to empty response
      new("assistant", SamplingMessageContent.text(""), "unknown")
    end
  end

  # Base class for all sampling methods
  abstract class SamplingMethod
    # Name of the sampling method
    getter name : String

    # Description of the sampling method
    getter description : String

    # Initialize a new sampling method
    def initialize(@name : String, @description : String)
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      result = {} of String => JsonValue

      # Add required fields
      result["name"] = @name
      result["description"] = @description
      result["parameters"] = parameters_schema

      result
    end

    # Return the parameters schema
    abstract def parameters_schema : JsonObject

    # Execute sampling
    abstract def sample(text : String, params : JsonObject?, context : Context) : JsonObject
  end

  # Greedy sampling method
  class GreedySamplingMethod < SamplingMethod
    def initialize
      super("greedy", "Selects the token with the highest probability")
    end

    def parameters_schema : JsonObject
      {
        "type"       => "object",
        "properties" => {} of String => JsonValue,
        "required"   => [] of JsonValue,
      } of String => JsonValue
    end

    def sample(text : String, params : JsonObject?, context : Context) : JsonObject
      # In a real implementation, this would call an LLM API
      # This is a dummy implementation
      {
        "text" => "Sampling result: #{text}",
      } of String => JsonValue
    end
  end

  # Temperature sampling method
  class TemperatureSamplingMethod < SamplingMethod
    def initialize
      super("temperature", "Performs probabilistic sampling using a temperature parameter")
    end

    def parameters_schema : JsonObject
      {
        "type"       => "object",
        "properties" => {
          "temperature" => {
            "type"        => "number",
            "description" => "Temperature parameter (0.0 to 1.0)",
            "minimum"     => 0.0,
            "maximum"     => 1.0,
            "default"     => 0.7,
          } of String => JsonValue,
        } of String => JsonValue,
        "required" => ["temperature"] of JsonValue,
      } of String => JsonValue
    end

    def sample(text : String, params : JsonObject?, context : Context) : JsonObject
      # In a real implementation, this would call an LLM API
      # This is a dummy implementation
      temperature = 0.7

      if params
        temp_value = params["temperature"]?
        temperature = MocoPo.safe_float(temp_value) || 0.7
      end

      {
        "text" => "Sampling result (temperature: #{temperature}): #{text}",
      } of String => JsonValue
    end
  end

  # Top-K sampling method
  class TopKSamplingMethod < SamplingMethod
    def initialize
      super("top_k", "Selects from the top k tokens")
    end

    def parameters_schema : JsonObject
      {
        "type"       => "object",
        "properties" => {
          "k" => {
            "type"        => "integer",
            "description" => "Number of tokens to select from",
            "minimum"     => 1,
            "default"     => 40,
          } of String => JsonValue,
        } of String => JsonValue,
        "required" => ["k"] of JsonValue,
      } of String => JsonValue
    end

    def sample(text : String, params : JsonObject?, context : Context) : JsonObject
      # In a real implementation, this would call an LLM API
      # This is a dummy implementation
      k = 40

      if params
        k_value = params["k"]?
        k = MocoPo.safe_int(k_value) || 40
      end

      {
        "text" => "Sampling result (top_k: #{k}): #{text}",
      } of String => JsonValue
    end
  end

  # Top-P sampling method
  class TopPSamplingMethod < SamplingMethod
    def initialize
      super("top_p", "Selects from tokens until the cumulative probability exceeds p")
    end

    def parameters_schema : JsonObject
      {
        "type"       => "object",
        "properties" => {
          "p" => {
            "type"        => "number",
            "description" => "Cumulative probability threshold (0.0 to 1.0)",
            "minimum"     => 0.0,
            "maximum"     => 1.0,
            "default"     => 0.9,
          } of String => JsonValue,
        } of String => JsonValue,
        "required" => ["p"] of JsonValue,
      } of String => JsonValue
    end

    def sample(text : String, params : JsonObject?, context : Context) : JsonObject
      # In a real implementation, this would call an LLM API
      # This is a dummy implementation
      p = 0.9

      if params
        p_value = params["p"]?
        p = MocoPo.safe_float(p_value) || 0.9
      end

      {
        "text" => "Sampling result (top_p: #{p}): #{text}",
      } of String => JsonValue
    end
  end

  # Sampling error class
  class SamplingError < Exception
    # Error code
    property code : Int32

    # Initialize a new sampling error
    def initialize(@code : Int32, message : String)
      super(message)
    end
  end

  # Sampling manager
  class SamplingManager
    # Map of sampling methods
    @methods : Hash(String, SamplingMethod)

    # Initialize a new sampling manager
    def initialize
      @methods = {} of String => SamplingMethod

      # Register default sampling methods
      register(GreedySamplingMethod.new)
      register(TemperatureSamplingMethod.new)
      register(TopKSamplingMethod.new)
      register(TopPSamplingMethod.new)
    end

    # Register a sampling method
    def register(method : SamplingMethod)
      @methods[method.name] = method
    end

    # Check if a sampling method exists
    def exists?(name : String) : Bool
      @methods.has_key?(name)
    end

    # Get a sampling method
    def get(name : String) : SamplingMethod?
      @methods[name]?
    end

    # Get all sampling methods
    def list : Array(SamplingMethod)
      @methods.values
    end

    # Create a message (dummy implementation)
    def create_message(request : SamplingRequest, context : Context) : SamplingResponse
      # In a real implementation, this would:
      # 1. Request human review of the prompt
      # 2. Call an LLM API
      # 3. Request human review of the response
      # 4. Return the approved response

      # For now, we'll just return a dummy response
      if request.messages.empty?
        raise SamplingError.new(-32602, "No messages provided")
      end

      # Get the last message
      last_message = request.messages.last

      # Create a response based on the last message
      response_text = "This is a dummy response to: #{last_message.content.text}"

      # Create a response
      SamplingResponse.new(
        "assistant",
        SamplingMessageContent.text(response_text),
        "dummy-model-v1",
        "endTurn"
      )
    end
  end
end
