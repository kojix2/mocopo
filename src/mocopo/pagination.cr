require "base64"
require "json"

module MocoPo
  # Pagination utilities for MCP list operations
  module Pagination
    # Default page size for paginated results
    DEFAULT_PAGE_SIZE = 50

    # Cursor data structure
    class Cursor
      # Page number (0-based)
      getter page : Int32

      # Page size
      getter page_size : Int32

      # Initialize a new cursor
      def initialize(@page = 0, @page_size = DEFAULT_PAGE_SIZE)
      end

      # Create a cursor from an encoded string
      def self.from_string(cursor_string : String?) : Cursor
        return new if cursor_string.nil? || cursor_string.empty?

        begin
          # Decode the base64 string
          decoded = Base64.decode_string(cursor_string)

          # Parse the JSON
          json = JSON.parse(decoded)

          # Extract page and page_size
          page = json["page"]?.try(&.as_i) || 0
          page_size = json["page_size"]?.try(&.as_i) || DEFAULT_PAGE_SIZE

          # Create a new cursor
          new(page, page_size)
        rescue ex
          # If there's an error, return a default cursor
          new
        end
      end

      # Convert the cursor to an encoded string
      def to_string : String
        # Create a JSON object
        json = {
          "page"      => @page,
          "page_size" => @page_size,
        }.to_json

        # Encode as base64
        Base64.strict_encode(json)
      end

      # Get the next cursor
      def next : Cursor
        Cursor.new(@page + 1, @page_size)
      end

      # Get the offset for database queries
      def offset : Int32
        @page * @page_size
      end

      # Get the limit for database queries
      def limit : Int32
        @page_size
      end
    end

    # Paginate a list of items
    def self.paginate(items : Array(T), cursor_string : String?) : {Array(T), String?} forall T
      cursor = Cursor.from_string(cursor_string)

      # Calculate start and end indices
      start_index = cursor.offset
      end_index = start_index + cursor.limit

      # Get the page of items
      page_items = items[start_index...end_index]

      # Determine if there are more items
      next_cursor = end_index < items.size ? cursor.next.to_string : nil

      {page_items, next_cursor}
    end
  end
end
