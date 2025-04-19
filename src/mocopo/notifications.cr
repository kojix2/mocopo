module MocoPo
  # Notification manager for MCP servers
  class NotificationManager
    # Server instance
    @server : Server

    # Initialize a new notification manager
    def initialize(@server : Server)
    end

    # Send a notification to all connected clients
    def send_notification(method : String, params : JsonRpcNotificationParams = nil)
      # Create a notification
      notification = JsonRpcNotification.new(method, params)

      # Get the notification as a JSON object
      json_object = notification.to_json_object

      # Send the notification through all active transports
      if transport_manager = @server.transport_manager
        transport_manager.@transports.each do |transport|
          begin
            transport.send(json_object)
          rescue ex : Exception
            puts "Failed to send notification through transport: #{ex.message}"
          end
        end
      end

      # Log the notification (for backward compatibility)
      puts "Broadcasting notification: #{json_object.to_json}"
    end

    # Send a prompts list changed notification
    def prompts_list_changed
      send_notification("notifications/prompts/list_changed")
    end

    # Send a resources list changed notification
    def resources_list_changed
      send_notification("notifications/resources/list_changed")
    end

    # Send a tools list changed notification
    def tools_list_changed
      send_notification("notifications/tools/list_changed")
    end

    # Send a resource updated notification
    def resource_updated(uri : String)
      # Create params
      params = {} of String => JsonValue
      params["uri"] = uri

      # Send notification
      send_notification("notifications/resources/updated", params)
    end
  end
end
