# MocoPo Notifications Guide

## Overview

The notifications feature in MocoPo allows servers to inform clients about changes to the available tools, resources, and prompts. This guide explains how to use the notification functionality in your MCP server.

## Notification Types

MocoPo supports the following notification types:

- **prompts/list_changed**: Sent when the list of available prompts changes (new prompts added or existing prompts removed).
- **resources/list_changed**: Sent when the list of available resources changes (new resources added or existing resources removed).
- **tools/list_changed**: Sent when the list of available tools changes (new tools added or existing tools removed).
- **resources/updated**: Sent when a specific resource's content has been updated.

## Architecture

The notification system consists of:

1. **NotificationManager**: Central component that handles sending notifications to clients.
2. **Manager Integration**: Each manager (PromptManager, ResourceManager, ToolManager) is integrated with the notification system to automatically send notifications when their lists change.

## Usage

### Server Setup

The notification system is automatically set up when you create a Server instance:

```crystal
server = MocoPo::Server.new("MyServer", "1.0.0")
```

### Automatic Notifications

Notifications are automatically sent when you:

- Register a new tool, resource, or prompt
- Remove an existing tool, resource, or prompt

For example:

```crystal
# This will trigger a tools/list_changed notification
server.register_tool("my_tool", "My tool description") do |tool|
  # Tool configuration...
end

# This will trigger a tools/list_changed notification
server.tool_manager.remove("my_tool")
```

### Manual Notifications

You can also manually send notifications when needed:

```crystal
# Notify that a resource has been updated
server.resource_manager.notify_resource_updated("file:///example.txt")

# Manually trigger list changed notifications
server.notification_manager.prompts_list_changed
server.notification_manager.resources_list_changed
server.notification_manager.tools_list_changed
```

## Client Handling

Clients should handle these notifications by:

1. Listening for notification messages from the server
2. Refreshing their cached lists when a list_changed notification is received
3. Updating or refreshing specific resources when a resource_updated notification is received

## Example

See `examples/notification_server.cr` for a complete example of a server that demonstrates the notification functionality.

## Best Practices

- **Batch Changes**: If making multiple changes at once, consider manually sending a single notification after all changes are complete, rather than relying on automatic notifications for each change.
- **Resource Updates**: Always notify clients when a resource's content changes, so they can refresh their cached copies.
- **Subscription Management**: For resources that change frequently, consider using the subscription system to allow clients to subscribe only to resources they're interested in.

## Implementation Details

The notification system uses JSON-RPC notifications to communicate with clients. Each notification includes:

- **jsonrpc**: Always "2.0"
- **method**: The notification method (e.g., "notifications/prompts/list_changed")
- **params**: Optional parameters specific to the notification type

For example, a resource_updated notification includes the URI of the updated resource:

```json
{
  "jsonrpc": "2.0",
  "method": "notifications/resources/updated",
  "params": {
    "uri": "file:///example.txt"
  }
}
```
