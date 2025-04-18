require "./types"
require "file_utils"

module MocoPo
  # Root class for file system access
  class Root
    # Root ID
    getter id : String

    # Root name
    getter name : String

    # Root description
    getter description : String

    # Root path
    getter path : String

    # Root read-only flag
    getter read_only : Bool

    # Initialize a new root
    def initialize(@id : String, @name : String, @description : String, @path : String, @read_only : Bool = true)
      path_obj = Path.new(@path)

      # Ensure path exists
      unless Dir.exists?(path_obj.to_s)
        raise ArgumentError.new("Root path does not exist: #{@path}")
      end

      # Ensure path is absolute
      unless path_obj.absolute?
        raise ArgumentError.new("Root path must be absolute: #{@path}")
      end
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      {
        "id"          => @id,
        "name"        => @name,
        "description" => @description,
        "readOnly"    => @read_only,
      } of String => JsonValue
    end

    # Check if a path is within this root
    def contains?(path : String) : Bool
      # Normalize paths using Path struct
      normalized_path = Path.new(path).expand
      normalized_root = Path.new(@path).expand

      # Check if path starts with root
      normalized_path.to_s.starts_with?(normalized_root.to_s)
    end

    # Get the relative path from this root
    def relative_path(path : String) : String
      # Normalize paths using Path struct
      normalized_path = Path.new(path).expand
      normalized_root = Path.new(@path).expand

      unless normalized_path.to_s.starts_with?(normalized_root.to_s)
        raise ArgumentError.new("Path is not within root: #{path}")
      end

      # Extract relative path and convert to POSIX format
      rel_path = normalized_path.to_s[normalized_root.to_s.size..-1]

      # Convert to POSIX path and ensure it starts with a slash
      posix_path = Path.posix(rel_path).to_s
      posix_path = "/" + posix_path.lstrip('/')
      posix_path
    end

    # Get the absolute path from a relative path
    def absolute_path(relative_path : String) : String
      # Remove leading slash if present
      relative_path = relative_path[1..-1] if relative_path.starts_with?("/")

      # Use Path.posix to ensure consistent forward slashes
      path = Path.new(@path).join(relative_path)
      Path.posix(path).to_s
    end

    # Check if a file exists
    def file_exists?(relative_path : String) : Bool
      # Get absolute path as Path object
      path = Path.new(absolute_path(relative_path))

      # Check if file exists (exists but not a directory)
      File.exists?(path.to_s) && !Dir.exists?(path.to_s)
    end

    # Check if a directory exists
    def directory_exists?(relative_path : String) : Bool
      # Get absolute path as Path object
      path = Path.new(absolute_path(relative_path))

      # Check if directory exists
      Dir.exists?(path.to_s)
    end

    # List files in a directory
    def list_directory(relative_path : String) : Array(String)
      # Get absolute path as Path object
      path = Path.new(absolute_path(relative_path))

      # Check if directory exists
      unless Dir.exists?(path.to_s)
        raise ArgumentError.new("Directory does not exist: #{relative_path}")
      end

      # List files
      Dir.entries(path.to_s).reject { |entry| entry == "." || entry == ".." }
    end

    # Read a file
    def read_file(relative_path : String) : String
      # Get absolute path as Path object
      path = Path.new(absolute_path(relative_path))

      # Check if file exists
      unless File.exists?(path.to_s) && !Dir.exists?(path.to_s)
        raise ArgumentError.new("File does not exist: #{relative_path}")
      end

      # Read file
      File.read(path.to_s)
    end

    # Write a file
    def write_file(relative_path : String, content : String) : Nil
      # Check if root is read-only
      if @read_only
        raise ArgumentError.new("Root is read-only: #{@id}")
      end

      # Get absolute path as Path object
      path = Path.new(absolute_path(relative_path))

      # Create parent directories
      parent_dir = path.parent
      FileUtils.mkdir_p(parent_dir.to_s)

      # Write file
      File.write(path.to_s, content)
    end

    # Delete a file
    def delete_file(relative_path : String) : Nil
      # Check if root is read-only
      if @read_only
        raise ArgumentError.new("Root is read-only: #{@id}")
      end

      # Get absolute path as Path object
      path = Path.new(absolute_path(relative_path))

      # Check if file exists
      unless File.exists?(path.to_s) && !Dir.exists?(path.to_s)
        raise ArgumentError.new("File does not exist: #{relative_path}")
      end

      # Delete file
      File.delete(path.to_s)
    end

    # Create a directory
    def create_directory(relative_path : String) : Nil
      # Check if root is read-only
      if @read_only
        raise ArgumentError.new("Root is read-only: #{@id}")
      end

      # Get absolute path as Path object
      path = Path.new(absolute_path(relative_path))

      # Create directory
      FileUtils.mkdir_p(path.to_s)
    end

    # Delete a directory
    def delete_directory(relative_path : String) : Nil
      # Check if root is read-only
      if @read_only
        raise ArgumentError.new("Root is read-only: #{@id}")
      end

      # Get absolute path as Path object
      path = Path.new(absolute_path(relative_path))

      # Check if directory exists
      unless Dir.exists?(path.to_s)
        raise ArgumentError.new("Directory does not exist: #{relative_path}")
      end

      # Delete directory
      FileUtils.rm_rf(path.to_s)
    end
  end

  # Root manager
  class RootManager
    # Map of roots
    @roots : Hash(String, Root)

    # Initialize a new root manager
    def initialize
      @roots = {} of String => Root
    end

    # Register a root
    def register(root : Root) : Root
      # Check if root ID already exists
      if @roots.has_key?(root.id)
        raise ArgumentError.new("Root ID already exists: #{root.id}")
      end

      # Register root
      @roots[root.id] = root

      # Return root
      root
    end

    # Register a root with parameters
    def register(id : String, name : String, description : String, path : String, read_only : Bool = true) : Root
      # Create root
      root = Root.new(id, name, description, path, read_only)

      # Register root
      register(root)
    end

    # Unregister a root
    def unregister(id : String) : Nil
      # Check if root exists
      unless @roots.has_key?(id)
        raise ArgumentError.new("Root does not exist: #{id}")
      end

      # Unregister root
      @roots.delete(id)
    end

    # Check if a root exists
    def exists?(id : String) : Bool
      @roots.has_key?(id)
    end

    # Get a root
    def get(id : String) : Root?
      @roots[id]?
    end

    # List all roots
    def list : Array(Root)
      @roots.values
    end

    # Find a root that contains a path
    def find_root_for_path(path : String) : Root?
      # Normalize path using Path struct
      normalized_path = Path.new(path).expand

      # Find root
      @roots.values.find { |root| root.contains?(normalized_path.to_s) }
    end

    # Get the root and relative path for a path
    def get_root_and_relative_path(path : String) : {Root, String}?
      # Find root
      root = find_root_for_path(path)

      # Return nil if no root found
      return nil unless root

      # Get relative path
      relative_path = root.relative_path(path)

      # Return root and relative path
      {root, relative_path}
    end
  end

  # Root error class
  class RootError < Exception
    # Error code
    property code : Int32

    # Initialize a new root error
    def initialize(@code : Int32, message : String)
      super(message)
    end
  end

  # Root file info class
  class RootFileInfo
    # File name
    getter name : String

    # File path
    getter path : String

    # File type
    getter type : String

    # File size
    getter size : Int64

    # File modification time
    getter modified : Time

    # Initialize a new file info
    def initialize(@name : String, @path : String, @type : String, @size : Int64, @modified : Time)
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      {
        "name"     => @name,
        "path"     => @path,
        "type"     => @type,
        "size"     => @size.to_i32,
        "modified" => @modified.to_unix.to_i32,
      } of String => JsonValue
    end

    # Create from a file path
    def self.from_file(path : String, relative_path : String) : RootFileInfo
      # Get file stats
      stat = File.info(path)

      # Determine file type
      type = stat.directory? ? "directory" : "file"

      # Create file info
      new(
        name: File.basename(path),
        path: relative_path,
        type: type,
        size: stat.size,
        modified: stat.modification_time
      )
    end
  end

  # Root directory listing class
  class RootDirectoryListing
    # Root ID
    getter root_id : String

    # Directory path
    getter path : String

    # Files
    getter files : Array(RootFileInfo)

    # Initialize a new directory listing
    def initialize(@root_id : String, @path : String, @files : Array(RootFileInfo))
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      files_array = [] of JsonValue
      @files.each do |file|
        files_array << file.to_json_object
      end

      {
        "rootId" => @root_id,
        "path"   => @path,
        "files"  => files_array,
      } of String => JsonValue
    end
  end

  # Root file content class
  class RootFileContent
    # Root ID
    getter root_id : String

    # File path
    getter path : String

    # File content
    getter content : String

    # Initialize a new file content
    def initialize(@root_id : String, @path : String, @content : String)
    end

    # Convert to JSON-compatible Hash
    def to_json_object : JsonObject
      {
        "rootId"  => @root_id,
        "path"    => @path,
        "content" => @content,
      } of String => JsonValue
    end
  end

  # Add root manager to server
  class Server
    # Root manager
    property root_manager : RootManager

    # Register a root
    def register_root(id : String, name : String, description : String, path : String, read_only : Bool = true) : Root
      @root_manager.register(id, name, description, path, read_only)
    end
  end
end
