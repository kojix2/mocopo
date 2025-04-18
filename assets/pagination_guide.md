# MocoPo Pagination Guide

## Overview

This guide explains the pagination support in MocoPo for handling large result sets in list operations. Pagination allows servers to return results in smaller chunks rather than all at once, improving performance and reducing memory usage.

## Pagination Model

MocoPo implements cursor-based pagination as specified in the Model Context Protocol (MCP). This approach uses an opaque cursor token to represent a position in the result set, rather than using numbered pages.

Key features:
- Cursor tokens are base64-encoded JSON objects containing pagination metadata
- Default page size is 50 items per page
- Clients can request the next page by providing the cursor from the previous response

## Supported Operations

The following operations support pagination:

- `tools/list` - List available tools
- `resources/list` - List available resources
- `prompts/list` - List available prompts

## How to Use Pagination

### Client-Side

When making a request to a list endpoint, clients can include an optional `cursor` parameter:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/list",
  "params": {
    "cursor": "eyJwYWdlIjoxLCJwYWdlX3NpemUiOjUwfQ=="
  }
}
```

The server will respond with a page of results and a `nextCursor` if more results are available:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [...],
    "nextCursor": "eyJwYWdlIjoyLCJwYWdlX3NpemUiOjUwfQ=="
  }
}
```

To get the next page, clients should use the `nextCursor` value in their next request. If `nextCursor` is not present in the response, it means there are no more results.

### Server-Side

Server implementations using MocoPo automatically get pagination support for list operations. The pagination is handled by the `Pagination` module, which provides utilities for paginating arrays of items.

## Implementation Details

### Cursor Structure

The cursor is a base64-encoded JSON object with the following structure:

```json
{
  "page": 0,  // 0-based page number
  "page_size": 50  // Number of items per page
}
```

### Pagination Module

The `Pagination` module provides the following functionality:

- `Cursor` class for managing pagination state
- `paginate` method for paginating arrays of items

Example usage:

```crystal
# Get all items
items = get_all_items()

# Apply pagination
page_items, next_cursor = Pagination.paginate(items, cursor_string)

# Return paginated results
{
  "items" => page_items,
  "nextCursor" => next_cursor
}
```

## Example Server

See `examples/pagination_server.cr` for a complete example of a server that demonstrates pagination with a large number of tools, resources, and prompts.

To run the example:

```
crystal examples/pagination_server.cr
```

This will start a server on http://localhost:3000 and demonstrate pagination by making requests to list tools, resources, and prompts.

## Best Practices

1. **Always handle pagination in clients**: Clients should always be prepared to handle paginated responses, even if they expect small result sets.

2. **Treat cursors as opaque tokens**: Clients should not attempt to parse or modify cursor tokens, as their internal structure may change.

3. **Don't persist cursors**: Cursors are meant to be used within a single session and may become invalid over time as the underlying data changes.

4. **Set appropriate page sizes**: The default page size (50) works well for most use cases, but you may want to adjust it based on your specific needs.

## Error Handling

If an invalid cursor is provided, the server will ignore it and return the first page of results. This ensures that clients can recover from invalid cursor states without errors.
