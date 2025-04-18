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

      # In a real implementation, this would send the notification to all connected clients
      # For now, we just log it to the console
      puts "Broadcasting notification: #{notification.to_json_object.to_json}"
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
