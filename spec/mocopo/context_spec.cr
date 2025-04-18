require "../spec_helper"

describe MocoPo::Context do
  it "can be initialized with request ID, client ID, and server" do
    server = create_test_server
    context = MocoPo::Context.new("req-123", "client-456", server)

    context.request_id.should eq("req-123")
    context.client_id.should eq("client-456")
  end

  it "can log messages at different levels" do
    server = create_test_server
    context = MocoPo::Context.new("req-123", "client-456", server)

    # Since we're just logging to console, we can only verify that these don't raise errors
    context.debug("Debug message").should be_nil
    context.info("Info message").should be_nil
    context.warning("Warning message").should be_nil
    context.error("Error message").should be_nil
  end

  it "can report progress" do
    server = create_test_server
    context = MocoPo::Context.new("req-123", "client-456", server)

    # Since we're just logging to console, we can only verify that these don't raise errors
    context.report_progress(50, 100).should be_nil
    context.report_progress(75.5, 100.0, "Almost done").should be_nil
  end

  it "can read resources" do
    server = create_test_server

    # Register a test resource
    resource = MocoPo::Resource.new("test:///resource", "Test Resource")
    resource.on_read do |ctx|
      # Use the context if provided
      message = ctx ? "Resource with context (#{ctx.request_id})" : "Resource without context"
      MocoPo::ResourceContent.text(
        uri: "test:///resource",
        text: message,
        mime_type: "text/plain"
      )
    end
    server.resource_manager.register(resource)

    # Create a context
    context = MocoPo::Context.new("req-123", "client-456", server)

    # Read the resource using the context
    contents = context.read_resource("test:///resource")
    contents.size.should eq(1)
    contents[0].uri.should eq("test:///resource")
    contents[0].text.should eq("Resource with context (req-123)")

    # Read a non-existent resource
    context.read_resource("test:///nonexistent").should be_empty
  end
end
