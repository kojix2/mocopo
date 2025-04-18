module MocoPo
  # Context for tool and resource execution
  class Context
    # Request ID
    getter request_id : String

    # Client ID
    getter client_id : String

    # Server instance
    @server : Server

    # Initialize a new context
    def initialize(@request_id : String, @client_id : String, @server : Server)
    end

    # Log a debug message
    def debug(message : String)
      send_log_notification("debug", message)
    end

    # Log an info message
    def info(message : String)
      send_log_notification("info", message)
    end

    # Log a warning message
    def warning(message : String)
      send_log_notification("warning", message)
    end

    # Log an error message
    def error(message : String)
      send_log_notification("error", message)
    end

    # Report progress
    def report_progress(current : Int32 | Float64, total : Int32 | Float64, message : String? = nil)
      # Create params
      params = {} of String => JsonValue
      params["progressToken"] = @request_id
      params["progress"] = current
      params["total"] = total
      params["message"] = message if message

      # Create notification
      notification = {} of String => JsonValue
      notification["jsonrpc"] = "2.0"
      notification["method"] = "notifications/progress"
      notification["params"] = params

      # Send notification
      send_notification(notification)
    end

    # Read a resource
    def read_resource(uri : String) : Array(ResourceContent)
      if @server.resource_manager.exists?(uri)
        resource = @server.resource_manager.get(uri).not_nil!
        [resource.get_content(self)]
      else
        [] of ResourceContent
      end
    end

    # Send a log notification
    private def send_log_notification(level : String, message : String)
      # Create data
      data = {} of String => JsonValue
      data["message"] = message

      # Create params
      params = {} of String => JsonValue
      params["level"] = level
      params["data"] = data

      # Create notification
      notification = {} of String => JsonValue
      notification["jsonrpc"] = "2.0"
      notification["method"] = "notifications/message"
      notification["params"] = params

      # Send notification
      send_notification(notification)
    end

    # Send a notification
    private def send_notification(notification)
      # In a real implementation, this would send the notification to the client
      # For now, we just log it to the console
      puts "Notification: #{notification.to_json}"
    end
  end
end
