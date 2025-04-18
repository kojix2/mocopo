# MocoPo Security Guide

## Overview

This guide explains the security features implemented in MocoPo to help you build secure MCP servers. These features include input validation, access control, rate limiting, and output sanitization.

## Input Validation

Input validation is a critical security feature that ensures all arguments passed to tools meet the expected format and constraints. MocoPo implements input validation in the `Tool` class.

### How It Works

1. Each tool has an input schema defined using JSON Schema.
2. When a tool is executed, the arguments are validated against this schema.
3. Required fields are checked to ensure they are present.
4. Type checking is performed to ensure arguments match their expected types.

### Example

```crystal
# Register a tool with input validation
server.register_tool("echo", "Echo the input text") do |tool|
  tool.argument_string("text", true, "Text to echo")  # 'true' means this argument is required
  tool.on_execute do |args, context|
    # If 'text' is missing or not a string, validation will fail
    # and the tool will return an error
    text = args.try &.["text"]?.try &.as_s || ""
    # ...
  end
end
```

## Access Control

Access control restricts which clients can execute specific tools. This is implemented through an allowed clients list in the `Tool` class.

### How It Works

1. Each tool can have an `allowed_clients` property set to an array of client IDs.
2. When a tool is executed, the client ID from the context is checked against this list.
3. If the client ID is not in the list, the tool execution is denied.

### Example

```crystal
# Register a tool with access control
server.register_tool("admin_tool", "Tool only for admins") do |tool|
  tool.argument_string("command", true, "Admin command")
  # Set allowed clients
  tool.allowed_clients = ["admin-client-1", "admin-client-2"]
  tool.on_execute do |args, context|
    # Only clients with IDs "admin-client-1" or "admin-client-2"
    # will be allowed to execute this tool
    # ...
  end
end
```

## Rate Limiting

Rate limiting prevents abuse by limiting how many times a client can call tools within a specific time window. This is implemented in the `ToolManager` class.

### How It Works

1. The `ToolManager` keeps track of tool calls per client ID.
2. Each call is timestamped and stored in a log.
3. When a tool is executed, the log is checked to see if the client has exceeded the rate limit.
4. If the rate limit is exceeded, the tool execution is denied.

### Configuration

The rate limit is configured with two constants in the `ToolManager` class:

```crystal
RATE_LIMIT_WINDOW = 10 # seconds
RATE_LIMIT_MAX_CALLS = 5 # maximum calls per window
```

This means each client can make at most 5 calls within a 10-second window.

## Output Sanitization

Output sanitization prevents cross-site scripting (XSS) attacks by escaping HTML special characters in tool output. This is implemented in the `Tool` class.

### How It Works

1. When a tool is executed, the output is checked for text content.
2. Any text content is HTML-escaped to prevent XSS attacks.
3. The escaped text is returned to the client.

### Example

```crystal
# Register a tool that demonstrates output sanitization
server.register_tool("html_tool", "Tool that returns HTML") do |tool|
  tool.argument_string("html", false, "HTML to sanitize")
  tool.on_execute do |args, context|
    html = args.try &.["html"]?.try &.as_s || "<script>alert('XSS')</script>"
    # The output will be sanitized automatically
    # "<script>alert('XSS')</script>" becomes "&lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;"
    # ...
  end
end
```

## Best Practices

1. **Always validate input**: Use the built-in validation features to ensure all arguments meet your expectations.
2. **Implement access control**: Restrict sensitive tools to authorized clients only.
3. **Set appropriate rate limits**: Adjust the rate limit constants based on your server's capacity and expected usage.
4. **Sanitize all output**: Ensure all text output is properly sanitized to prevent XSS attacks.
5. **Use the execute_tool method**: Always use the `execute_tool` method in the `ToolManager` class to execute tools, as it enforces all security features.

## Example Server

See `examples/security_server.cr` for a complete example of a server that demonstrates all security features.

## Advanced Security Considerations

For production deployments, consider implementing additional security measures:

1. **TLS/SSL**: Use HTTPS to encrypt all communication between clients and your server.
2. **Authentication**: Implement a robust authentication system to verify client identities.
3. **Logging**: Log all tool executions and security events for auditing purposes.
4. **Monitoring**: Set up monitoring to detect and respond to suspicious activity.
5. **Regular Updates**: Keep your MocoPo installation and dependencies up to date with security patches.
