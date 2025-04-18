require "./types"

module MocoPo
  # Cancellation token class
  class CancellationToken
    # Token ID
    getter id : String

    # Cancellation status
    getter cancelled : Bool

    # Cancellation reason
    getter reason : String?

    # Initialize a new cancellation token
    def initialize(@id : String)
      @cancelled = false
      @reason = nil
    end

    # Cancel the token
    def cancel(reason : String? = nil)
      @cancelled = true
      @reason = reason
    end

    # Check if the token is cancelled
    def cancelled?
      @cancelled
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      result = {
        "id"        => @id,
        "cancelled" => @cancelled,
      } of String => JsonValue

      # Add reason if present
      if reason = @reason
        result["reason"] = reason
      end

      result
    end
  end

  # Cancellation manager
  class CancellationManager
    # Map of tokens
    @tokens : Hash(String, CancellationToken)

    # Initialize a new cancellation manager
    def initialize
      @tokens = {} of String => CancellationToken
    end

    # Create a new token
    def create_token(id : String? = nil) : CancellationToken
      # Generate a random ID if not provided
      id = id || Random.new.hex(16)

      # Create a new token
      token = CancellationToken.new(id)

      # Register the token
      @tokens[id] = token

      # Return the token
      token
    end

    # Get a token by ID
    def get_token(id : String) : CancellationToken?
      @tokens[id]?
    end

    # Cancel a token by ID
    def cancel_token(id : String, reason : String? = nil) : Bool
      # Get the token
      token = get_token(id)

      # Return false if the token does not exist
      return false unless token

      # Cancel the token
      token.cancel(reason)

      # Return true
      true
    end

    # Check if a token is cancelled
    def is_cancelled?(id : String) : Bool
      # Get the token
      token = get_token(id)

      # Return false if the token does not exist
      return false unless token

      # Return the cancellation status
      token.cancelled?
    end

    # List all tokens
    def list : Array(CancellationToken)
      @tokens.values
    end

    # Remove a token by ID
    def remove_token(id : String) : Bool
      # Return false if the token does not exist
      return false unless @tokens.has_key?(id)

      # Remove the token
      @tokens.delete(id)

      # Return true
      true
    end

    # Clear all tokens
    def clear
      @tokens.clear
    end
  end

  # Add cancellation manager to server
  class Server
    # Cancellation manager
    property cancellation_manager : CancellationManager

    # Initialize cancellation manager
    def initialize_cancellation_manager
      @cancellation_manager = CancellationManager.new
    end

    # Create a cancellation token
    def create_cancellation_token(id : String? = nil) : CancellationToken
      @cancellation_manager.create_token(id)
    end

    # Cancel a token
    def cancel_token(id : String, reason : String? = nil) : Bool
      @cancellation_manager.cancel_token(id, reason)
    end

    # Check if a token is cancelled
    def is_cancelled?(id : String) : Bool
      @cancellation_manager.is_cancelled?(id)
    end
  end
end
