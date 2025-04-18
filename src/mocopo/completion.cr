module MocoPo
  # Completion utilities for MCP
  module Completion
    # Maximum number of completion values to return
    MAX_COMPLETION_VALUES = 100

    # Reference types for completion
    enum ReferenceType
      Prompt
      Resource
    end

    # Reference for completion
    class Reference
      # Reference type
      getter type : ReferenceType

      # Reference name or URI
      getter identifier : String

      # Initialize a new reference
      def initialize(@type : ReferenceType, @identifier : String)
      end

      # Create a reference from a JSON object
      def self.from_json(json : Hash(String, JSON::Any)) : Reference?
        type_str = json["type"]?.try &.as_s
        return nil unless type_str

        case type_str
        when "ref/prompt"
          name = json["name"]?.try &.as_s
          return nil unless name
          new(ReferenceType::Prompt, name)
        when "ref/resource"
          uri = json["uri"]?.try &.as_s
          return nil unless uri
          new(ReferenceType::Resource, uri)
        else
          nil
        end
      end
    end

    # Argument for completion
    class Argument
      # Argument name
      getter name : String

      # Current value
      getter value : String

      # Initialize a new argument
      def initialize(@name : String, @value : String)
      end

      # Create an argument from a JSON object
      def self.from_json(json : Hash(String, JSON::Any)) : Argument?
        name = json["name"]?.try &.as_s
        value = json["value"]?.try &.as_s
        return nil unless name && value
        new(name, value)
      end
    end

    # Completion result
    class Result
      # Completion values
      getter values : Array(String)

      # Total number of matches
      getter total : Int32?

      # Whether there are more results
      getter has_more : Bool

      # Initialize a new completion result
      def initialize(@values : Array(String), @total : Int32? = nil, @has_more : Bool = false)
      end

      # Convert to JSON-compatible Hash
      def to_json_object
        result = {
          "values"  => @values,
          "hasMore" => @has_more,
        } of String => Array(String) | Int32 | Bool | Nil

        result["total"] = @total if @total

        result
      end
    end

    # Complete an argument value
    def self.complete(ref : Reference, arg : Argument, server : Server) : Result
      case ref.type
      when ReferenceType::Prompt
        complete_prompt_argument(ref.identifier, arg, server)
      when ReferenceType::Resource
        complete_resource_argument(ref.identifier, arg, server)
      else
        Result.new([] of String)
      end
    end

    # Complete a prompt argument
    private def self.complete_prompt_argument(prompt_name : String, arg : Argument, server : Server) : Result
      # Get the prompt
      prompt = server.prompt_manager.get(prompt_name)
      return Result.new([] of String) unless prompt

      # Find the argument
      prompt_arg = prompt.arguments.find { |a| a.name == arg.name }
      return Result.new([] of String) unless prompt_arg

      # Generate completion values based on the argument name and current value
      # This is a simple implementation that just returns some example values
      # In a real implementation, this would be more sophisticated
      case arg.name
      when "language"
        # Example: language completion
        languages = ["javascript", "typescript", "python", "ruby", "crystal", "go", "rust", "java", "c", "cpp", "csharp", "php"]
        filtered = languages.select { |l| l.starts_with?(arg.value.downcase) }
        Result.new(filtered[0...MAX_COMPLETION_VALUES], filtered.size, filtered.size > MAX_COMPLETION_VALUES)
      when "format"
        # Example: format completion
        formats = ["json", "yaml", "xml", "csv", "markdown", "html", "text"]
        filtered = formats.select { |f| f.starts_with?(arg.value.downcase) }
        Result.new(filtered[0...MAX_COMPLETION_VALUES], filtered.size, filtered.size > MAX_COMPLETION_VALUES)
      else
        # Default: empty completion
        Result.new([] of String)
      end
    end

    # Complete a resource argument
    private def self.complete_resource_argument(uri : String, arg : Argument, server : Server) : Result
      # This is a simple implementation that just returns some example values
      # In a real implementation, this would be more sophisticated
      case arg.name
      when "path"
        # Example: path completion
        paths = ["/home/user/", "/home/user/documents/", "/home/user/downloads/", "/home/user/pictures/"]
        filtered = paths.select { |p| p.starts_with?(arg.value) }
        Result.new(filtered[0...MAX_COMPLETION_VALUES], filtered.size, filtered.size > MAX_COMPLETION_VALUES)
      when "type"
        # Example: type completion
        types = ["file", "directory", "symlink", "socket", "pipe", "device"]
        filtered = types.select { |t| t.starts_with?(arg.value.downcase) }
        Result.new(filtered[0...MAX_COMPLETION_VALUES], filtered.size, filtered.size > MAX_COMPLETION_VALUES)
      else
        # Default: empty completion
        Result.new([] of String)
      end
    end
  end
end
