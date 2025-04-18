require "../spec_helper"

describe MocoPo::Resource do
  it "can be initialized with uri and name" do
    resource = MocoPo::Resource.new("file:///test", "Test Resource")

    resource.uri.should eq("file:///test")
    resource.name.should eq("Test Resource")
    resource.description.should be_nil
    resource.mime_type.should be_nil
    resource.size.should be_nil
  end

  it "can be initialized with optional parameters" do
    resource = MocoPo::Resource.new(
      uri: "file:///test",
      name: "Test Resource",
      description: "A test resource",
      mime_type: "text/plain",
      size: 1024_i64
    )

    resource.uri.should eq("file:///test")
    resource.name.should eq("Test Resource")
    resource.description.should eq("A test resource")
    resource.mime_type.should eq("text/plain")
    resource.size.should eq(1024_i64)
  end

  it "can set and get content" do
    resource = MocoPo::Resource.new("file:///test", "Test Resource")
    resource.on_read do
      MocoPo::ResourceContent.text(
        uri: "file:///test",
        text: "Hello, World!",
        mime_type: "text/plain"
      )
    end

    content = resource.get_content
    content.uri.should eq("file:///test")
    content.text.should eq("Hello, World!")
    content.mime_type.should eq("text/plain")
    content.blob.should be_nil
  end

  it "returns a default content when no callback is set" do
    resource = MocoPo::Resource.new("file:///test", "Test Resource")

    content = resource.get_content
    content.uri.should eq("file:///test")
    content.text.should eq("Resource content not implemented for: file:///test")
    content.mime_type.should eq("text/plain")
    content.blob.should be_nil
  end

  it "converts to a JSON-compatible hash" do
    resource = MocoPo::Resource.new(
      uri: "file:///test",
      name: "Test Resource",
      description: "A test resource",
      mime_type: "text/plain",
      size: 1024_i64
    )

    json = resource.to_json_object
    json["uri"].should eq("file:///test")
    json["name"].should eq("Test Resource")
    json["description"].should eq("A test resource")
    json["mimeType"].should eq("text/plain")
    json["size"].should eq(1024_i64)
  end
end

describe MocoPo::ResourceContent do
  it "can be created as text content" do
    content = MocoPo::ResourceContent.text(
      uri: "file:///test",
      text: "Hello, World!",
      mime_type: "text/plain"
    )

    content.uri.should eq("file:///test")
    content.text.should eq("Hello, World!")
    content.mime_type.should eq("text/plain")
    content.blob.should be_nil
  end

  it "can be created as binary content" do
    content = MocoPo::ResourceContent.binary(
      uri: "file:///test.png",
      blob: "base64data",
      mime_type: "image/png"
    )

    content.uri.should eq("file:///test.png")
    content.blob.should eq("base64data")
    content.mime_type.should eq("image/png")
    content.text.should be_nil
  end

  it "converts to a JSON-compatible hash" do
    content = MocoPo::ResourceContent.text(
      uri: "file:///test",
      text: "Hello, World!",
      mime_type: "text/plain"
    )

    json = content.to_json_object
    json["uri"].should eq("file:///test")
    json["text"].should eq("Hello, World!")
    json["mimeType"].should eq("text/plain")
    json.has_key?("blob").should be_false
  end
end

describe MocoPo::ResourceManager do
  it "can register and retrieve resources" do
    manager = MocoPo::ResourceManager.new

    resource1 = MocoPo::Resource.new("file:///test1", "Test Resource 1")
    resource2 = MocoPo::Resource.new("file:///test2", "Test Resource 2")

    manager.register(resource1)
    manager.register(resource2)

    manager.exists?("file:///test1").should be_true
    manager.exists?("file:///test2").should be_true
    manager.exists?("file:///test3").should be_false

    manager.get("file:///test1").should eq(resource1)
    manager.get("file:///test2").should eq(resource2)
    manager.get("file:///test3").should be_nil

    manager.list.size.should eq(2)
    manager.list.should contain(resource1)
    manager.list.should contain(resource2)
  end

  it "can remove resources" do
    manager = MocoPo::ResourceManager.new

    resource = MocoPo::Resource.new("file:///test", "Test Resource")

    manager.register(resource)
    manager.exists?("file:///test").should be_true

    manager.remove("file:///test")
    manager.exists?("file:///test").should be_false
  end

  it "can manage subscriptions" do
    manager = MocoPo::ResourceManager.new

    resource = MocoPo::Resource.new("file:///test", "Test Resource")
    manager.register(resource)

    # Initially no subscribers
    manager.subscribers("file:///test").size.should eq(0)

    # Add subscribers
    manager.subscribe("file:///test", "client1")
    manager.subscribe("file:///test", "client2")

    manager.subscribers("file:///test").size.should eq(2)
    manager.subscribers("file:///test").should contain("client1")
    manager.subscribers("file:///test").should contain("client2")

    # Remove a subscriber
    manager.unsubscribe("file:///test", "client1")

    manager.subscribers("file:///test").size.should eq(1)
    manager.subscribers("file:///test").should_not contain("client1")
    manager.subscribers("file:///test").should contain("client2")

    # Subscribing to a non-existent resource should still work
    manager.subscribe("file:///nonexistent", "client3")
    manager.subscribers("file:///nonexistent").size.should eq(1)
    manager.subscribers("file:///nonexistent").should contain("client3")
  end
end
