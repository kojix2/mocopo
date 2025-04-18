# MocoPo Roots Guide

## Overview

The roots feature in MocoPo allows servers to expose specific directories on the file system to clients in a secure and controlled manner. This guide explains how to use the roots functionality in your MCP server.

## Concepts

### Root

A root is a specific directory on the file system that is exposed to clients. Each root has:

- **ID**: A unique identifier for the root
- **Name**: A human-readable name for the root
- **Description**: A description of the root
- **Path**: The absolute path to the directory on the file system
- **Read-only flag**: Whether the root is read-only or writable

### File System Operations

The roots feature supports the following file system operations:

- **List directory**: List files and directories in a directory
- **Read file**: Read the contents of a file
- **Write file**: Write contents to a file (if the root is writable)
- **Delete file**: Delete a file (if the root is writable)
- **Create directory**: Create a directory (if the root is writable)
- **Delete directory**: Delete a directory (if the root is writable)

## API

### Roots Methods

MocoPo provides several roots methods:

- **roots/list**: List all registered roots
- **roots/listDirectory**: List files and directories in a directory
- **roots/readFile**: Read the contents of a file
- **roots/writeFile**: Write contents to a file
- **roots/deleteFile**: Delete a file
- **roots/createDirectory**: Create a directory
- **roots/deleteDirectory**: Delete a directory

### Roots/List Request

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "roots/list"
}
```

### Roots/List Response

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "roots": [
      {
        "id": "current",
        "name": "Current Directory",
        "description": "The current working directory",
        "readOnly": true
      },
      {
        "id": "temp",
        "name": "Temp Directory",
        "description": "A writable temporary directory",
        "readOnly": false
      }
    ]
  }
}
```

### Roots/ListDirectory Request

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "roots/listDirectory",
  "params": {
    "rootId": "current",
    "path": "/"
  }
}
```

### Roots/ListDirectory Response

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "rootId": "current",
    "path": "/",
    "files": [
      {
        "name": "src",
        "path": "/src",
        "type": "directory",
        "size": 4096,
        "modified": 1617235678
      },
      {
        "name": "README.md",
        "path": "/README.md",
        "type": "file",
        "size": 1024,
        "modified": 1617235678
      }
    ]
  }
}
```

### Roots/ReadFile Request

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "roots/readFile",
  "params": {
    "rootId": "current",
    "path": "/README.md"
  }
}
```

### Roots/ReadFile Response

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "rootId": "current",
    "path": "/README.md",
    "content": "# MocoPo\n\nA Crystal library for building MCP servers."
  }
}
```

### Roots/WriteFile Request

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "roots/writeFile",
  "params": {
    "rootId": "temp",
    "path": "/new_file.txt",
    "content": "This is a new file created via the roots API."
  }
}
```

### Roots/WriteFile Response

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": {}
}
```

### Roots/DeleteFile Request

```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "roots/deleteFile",
  "params": {
    "rootId": "temp",
    "path": "/new_file.txt"
  }
}
```

### Roots/DeleteFile Response

```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "result": {}
}
```

### Roots/CreateDirectory Request

```json
{
  "jsonrpc": "2.0",
  "id": 6,
  "method": "roots/createDirectory",
  "params": {
    "rootId": "temp",
    "path": "/new_directory"
  }
}
```

### Roots/CreateDirectory Response

```json
{
  "jsonrpc": "2.0",
  "id": 6,
  "result": {}
}
```

### Roots/DeleteDirectory Request

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "method": "roots/deleteDirectory",
  "params": {
    "rootId": "temp",
    "path": "/new_directory"
  }
}
```

### Roots/DeleteDirectory Response

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "result": {}
}
```

## Example Usage

```crystal
# Create a new MCP server
server = MocoPo::Server.new(
  name: "RootsMCPServer",
  version: "1.0.0"
)

# Register a read-only root
server.register_root(
  "current",
  "Current Directory",
  "The current working directory",
  Dir.current,
  true # read-only
)

# Create a writable temp directory
temp_dir = File.join(Dir.tempdir, "mocopo_roots_example")
Dir.mkdir_p(temp_dir) unless Dir.exists?(temp_dir)

# Register a writable root
server.register_root(
  "temp",
  "Temp Directory",
  "A writable temporary directory",
  temp_dir,
  false # writable
)

# Start the server
server.start
```

## Best Practices

- **Security**: Be careful when exposing directories on the file system. Only expose directories that are safe to access.
- **Read-only vs. Writable**: Use read-only roots for directories that should not be modified by clients. Use writable roots for directories that can be modified by clients.
- **Path Validation**: Always validate paths to ensure they are within the root directory. MocoPo does this automatically, but it's good to be aware of it.
- **Error Handling**: Handle errors gracefully. MocoPo provides error responses for invalid requests, but you may want to add additional error handling in your application.

## Security Considerations

- **Path Traversal**: MocoPo prevents path traversal attacks by validating paths to ensure they are within the root directory.
- **File System Access**: Be careful when exposing directories on the file system. Only expose directories that are safe to access.
- **Read-only vs. Writable**: Use read-only roots for directories that should not be modified by clients. Use writable roots for directories that can be modified by clients.
