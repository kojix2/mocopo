module MocoPo
  # Handler for roots methods
  class RootsHandler < BaseHandler
    # Handle roots/list request
    def handle_list(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # Get all roots
      roots = @server.root_manager.list

      # Convert to JSON-compatible format
      roots_array = [] of JsonValue
      roots.each do |root|
        roots_array << root.to_json_object
      end

      # Return the list of roots
      result = {} of String => JsonValue
      result["roots"] = roots_array
      success_response(id, result)
    end

    # Handle roots/listDirectory request
    def handle_list_directory(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      begin
        # Validate parameters
        unless params
          return error_response(-32602, "Missing parameters", id)
        end

        # Extract root ID and path
        root_id = MocoPo.safe_string(params["rootId"]?)
        path = MocoPo.safe_string(params["path"]?)

        # Validate root ID
        unless root_id && @server.root_manager.exists?(root_id)
          return error_response(-32602, "Unknown root ID: #{root_id || "missing root ID"}", id)
        end

        # Get root
        root = @server.root_manager.get(root_id).not_nil!

        # Validate path
        unless path
          return error_response(-32602, "Missing path parameter", id)
        end

        # Check if directory exists
        unless root.directory_exists?(path)
          return error_response(-32602, "Directory does not exist: #{path}", id)
        end

        # Get absolute path
        absolute_path = root.absolute_path(path)

        # List files
        entries = root.list_directory(path)

        # Create file info objects
        files = [] of RootFileInfo
        entries.each do |entry|
          # Get entry path
          entry_path = File.join(path, entry)
          entry_path = entry_path[1..-1] if entry_path.starts_with?("//")
          entry_path = "/#{entry_path}" unless entry_path.starts_with?("/")

          # Get absolute entry path
          absolute_entry_path = root.absolute_path(entry_path)

          # Create file info
          files << RootFileInfo.from_file(absolute_entry_path, entry_path)
        end

        # Create directory listing
        listing = RootDirectoryListing.new(root_id, path, files)

        # Return the directory listing
        success_response(id, listing.to_json_object)
      rescue ex : ArgumentError
        # Handle argument errors
        error_response(-32602, ex.message || "Unknown error", id)
      rescue ex
        # Handle other errors
        error_response(-32603, "Error listing directory: #{ex.message}", id)
      end
    end

    # Handle roots/readFile request
    def handle_read_file(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      begin
        # Validate parameters
        unless params
          return error_response(-32602, "Missing parameters", id)
        end

        # Extract root ID and path
        root_id = MocoPo.safe_string(params["rootId"]?)
        path = MocoPo.safe_string(params["path"]?)

        # Validate root ID
        unless root_id && @server.root_manager.exists?(root_id)
          return error_response(-32602, "Unknown root ID: #{root_id || "missing root ID"}", id)
        end

        # Get root
        root = @server.root_manager.get(root_id).not_nil!

        # Validate path
        unless path
          return error_response(-32602, "Missing path parameter", id)
        end

        # Check if file exists
        unless root.file_exists?(path)
          return error_response(-32602, "File does not exist: #{path}", id)
        end

        # Read file
        content = root.read_file(path)

        # Create file content
        file_content = RootFileContent.new(root_id, path, content)

        # Return the file content
        success_response(id, file_content.to_json_object)
      rescue ex : ArgumentError
        # Handle argument errors
        error_response(-32602, ex.message || "Unknown error", id)
      rescue ex
        # Handle other errors
        error_response(-32603, "Error reading file: #{ex.message || "Unknown error"}", id)
      end
    end

    # Handle roots/writeFile request
    def handle_write_file(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      begin
        # Validate parameters
        unless params
          return error_response(-32602, "Missing parameters", id)
        end

        # Extract root ID, path, and content
        root_id = MocoPo.safe_string(params["rootId"]?)
        path = MocoPo.safe_string(params["path"]?)
        content = MocoPo.safe_string(params["content"]?)

        # Validate root ID
        unless root_id && @server.root_manager.exists?(root_id)
          return error_response(-32602, "Unknown root ID: #{root_id || "missing root ID"}", id)
        end

        # Get root
        root = @server.root_manager.get(root_id).not_nil!

        # Validate path
        unless path
          return error_response(-32602, "Missing path parameter", id)
        end

        # Validate content
        unless content
          return error_response(-32602, "Missing content parameter", id)
        end

        # Write file
        root.write_file(path, content)

        # Return success
        success_response(id, {} of String => JsonValue)
      rescue ex : ArgumentError
        # Handle argument errors
        error_response(-32602, ex.message || "Unknown error", id)
      rescue ex
        # Handle other errors
        error_response(-32603, "Error writing file: #{ex.message || "Unknown error"}", id)
      end
    end

    # Handle roots/deleteFile request
    def handle_delete_file(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      begin
        # Validate parameters
        unless params
          return error_response(-32602, "Missing parameters", id)
        end

        # Extract root ID and path
        root_id = MocoPo.safe_string(params["rootId"]?)
        path = MocoPo.safe_string(params["path"]?)

        # Validate root ID
        unless root_id && @server.root_manager.exists?(root_id)
          return error_response(-32602, "Unknown root ID: #{root_id || "missing root ID"}", id)
        end

        # Get root
        root = @server.root_manager.get(root_id).not_nil!

        # Validate path
        unless path
          return error_response(-32602, "Missing path parameter", id)
        end

        # Delete file
        root.delete_file(path)

        # Return success
        success_response(id, {} of String => JsonValue)
      rescue ex : ArgumentError
        # Handle argument errors
        error_response(-32602, ex.message || "Unknown error", id)
      rescue ex
        # Handle other errors
        error_response(-32603, "Error deleting file: #{ex.message || "Unknown error"}", id)
      end
    end

    # Handle roots/createDirectory request
    def handle_create_directory(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      begin
        # Validate parameters
        unless params
          return error_response(-32602, "Missing parameters", id)
        end

        # Extract root ID and path
        root_id = MocoPo.safe_string(params["rootId"]?)
        path = MocoPo.safe_string(params["path"]?)

        # Validate root ID
        unless root_id && @server.root_manager.exists?(root_id)
          return error_response(-32602, "Unknown root ID: #{root_id || "missing root ID"}", id)
        end

        # Get root
        root = @server.root_manager.get(root_id).not_nil!

        # Validate path
        unless path
          return error_response(-32602, "Missing path parameter", id)
        end

        # Create directory
        root.create_directory(path)

        # Return success
        success_response(id, {} of String => JsonValue)
      rescue ex : ArgumentError
        # Handle argument errors
        error_response(-32602, ex.message || "Unknown error", id)
      rescue ex
        # Handle other errors
        error_response(-32603, "Error creating directory: #{ex.message || "Unknown error"}", id)
      end
    end

    # Handle roots/deleteDirectory request
    def handle_delete_directory(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      begin
        # Validate parameters
        unless params
          return error_response(-32602, "Missing parameters", id)
        end

        # Extract root ID and path
        root_id = MocoPo.safe_string(params["rootId"]?)
        path = MocoPo.safe_string(params["path"]?)

        # Validate root ID
        unless root_id && @server.root_manager.exists?(root_id)
          return error_response(-32602, "Unknown root ID: #{root_id || "missing root ID"}", id)
        end

        # Get root
        root = @server.root_manager.get(root_id).not_nil!

        # Validate path
        unless path
          return error_response(-32602, "Missing path parameter", id)
        end

        # Delete directory
        root.delete_directory(path)

        # Return success
        success_response(id, {} of String => JsonValue)
      rescue ex : ArgumentError
        # Handle argument errors
        error_response(-32602, ex.message || "Unknown error", id)
      rescue ex
        # Handle other errors
        error_response(-32603, "Error deleting directory: #{ex.message || "Unknown error"}", id)
      end
    end

    # Handle a JSON-RPC request
    def handle(id : JsonRpcId, params : JsonRpcParams) : JsonObject
      # This method should not be called directly
      error_response(-32603, "RootsHandler.handle called directly", id)
    end

    # Handle a JSON-RPC request with method
    def handle(id : JsonRpcId, method : String, params : JsonRpcParams) : JsonObject
      case method
      when "roots/list"
        handle_list(id, params)
      when "roots/listDirectory"
        handle_list_directory(id, params)
      when "roots/readFile"
        handle_read_file(id, params)
      when "roots/writeFile"
        handle_write_file(id, params)
      when "roots/deleteFile"
        handle_delete_file(id, params)
      when "roots/createDirectory"
        handle_create_directory(id, params)
      when "roots/deleteDirectory"
        handle_delete_directory(id, params)
      else
        error_response(-32601, "Method not found: #{method}", id)
      end
    end
  end
end
