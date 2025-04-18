require "../spec_helper"

describe MocoPo::Tool do
  it "can be initialized with name and description" do
    schema = {
      "type"       => JSON::Any.new("object"),
      "properties" => JSON::Any.new(Hash(String, JSON::Any).new),
      "required"   => JSON::Any.new([] of JSON::Any),
    }

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)

    tool.name.should eq("test_tool")
    tool.description.should eq("A test tool")
    tool.input_schema.should eq(schema)
  end

  it "can add string arguments" do
    schema = {
      "type"       => JSON::Any.new("object"),
      "properties" => JSON::Any.new(Hash(String, JSON::Any).new),
      "required"   => JSON::Any.new([] of JSON::Any),
    }

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)
    tool.argument_string("name", true, "Name to greet")

    # Check that the input schema was updated
    tool.input_schema["properties"].as_h.has_key?("name").should be_true
    tool.input_schema["properties"].as_h["name"].as_h["type"].as_s.should eq("string")
    tool.input_schema["properties"].as_h["name"].as_h["description"].as_s.should eq("Name to greet")
    tool.input_schema["required"].as_a.should contain(JSON::Any.new("name"))
  end

  it "can add number arguments" do
    schema = {
      "type"       => JSON::Any.new("object"),
      "properties" => JSON::Any.new(Hash(String, JSON::Any).new),
      "required"   => JSON::Any.new([] of JSON::Any),
    }

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)
    tool.argument_number("age", false, "Age in years")

    # Check that the input schema was updated
    tool.input_schema["properties"].as_h.has_key?("age").should be_true
    tool.input_schema["properties"].as_h["age"].as_h["type"].as_s.should eq("number")
    tool.input_schema["properties"].as_h["age"].as_h["description"].as_s.should eq("Age in years")

    # Check if required key exists before testing it
    if tool.input_schema.has_key?("required")
      tool.input_schema["required"].as_a.should_not contain(JSON::Any.new("age"))
    end
  end

  it "can add boolean arguments" do
    schema = {
      "type"       => JSON::Any.new("object"),
      "properties" => JSON::Any.new(Hash(String, JSON::Any).new),
      "required"   => JSON::Any.new([] of JSON::Any),
    }

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)
    tool.argument_boolean("active", true, "Whether the user is active")

    # Check that the input schema was updated
    tool.input_schema["properties"].as_h.has_key?("active").should be_true
    tool.input_schema["properties"].as_h["active"].as_h["type"].as_s.should eq("boolean")
    tool.input_schema["properties"].as_h["active"].as_h["description"].as_s.should eq("Whether the user is active")
    tool.input_schema["required"].as_a.should contain(JSON::Any.new("active"))
  end

  it "can add array arguments" do
    schema = {
      "type"       => JSON::Any.new("object"),
      "properties" => JSON::Any.new(Hash(String, JSON::Any).new),
      "required"   => JSON::Any.new([] of JSON::Any),
    }

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)
    tool.argument_array("tags", "string", false, "Tags for the item")

    # Check that the input schema was updated
    tool.input_schema["properties"].as_h.has_key?("tags").should be_true
    tool.input_schema["properties"].as_h["tags"].as_h["type"].as_s.should eq("array")
    tool.input_schema["properties"].as_h["tags"].as_h["description"].as_s.should eq("Tags for the item")
    tool.input_schema["properties"].as_h["tags"].as_h["items"].as_h["type"].as_s.should eq("string")

    # Check if required key exists before testing it
    if tool.input_schema.has_key?("required")
      tool.input_schema["required"].as_a.should_not contain(JSON::Any.new("tags"))
    end
  end

  it "can add object arguments" do
    schema = {
      "type"       => JSON::Any.new("object"),
      "properties" => JSON::Any.new(Hash(String, JSON::Any).new),
      "required"   => JSON::Any.new([] of JSON::Any),
    }

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)
    tool.argument_object("person", true, "Person information") do |obj|
      obj.string("first_name", true, "First name")
      obj.string("last_name", true, "Last name")
    end

    # Check that the input schema was updated
    tool.input_schema["properties"].as_h.has_key?("person").should be_true
    tool.input_schema["properties"].as_h["person"].as_h["type"].as_s.should eq("object")
    tool.input_schema["properties"].as_h["person"].as_h["description"].as_s.should eq("Person information")
    tool.input_schema["properties"].as_h["person"].as_h["properties"].as_h.has_key?("first_name").should be_true
    tool.input_schema["properties"].as_h["person"].as_h["properties"].as_h.has_key?("last_name").should be_true
    tool.input_schema["required"].as_a.should contain(JSON::Any.new("person"))
  end

  it "can set and execute a callback" do
    schema = {
      "type"       => JSON::Any.new("object"),
      "properties" => JSON::Any.new(Hash(String, JSON::Any).new),
      "required"   => JSON::Any.new([] of JSON::Any),
    }

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)
    tool.on_execute do |args|
      {
        "content" => [
          {
            "type" => "text",
            "text" => "Hello, World!",
          },
        ] of Hash(String, String),
        "isError" => "false",
      }
    end

    # Execute the tool
    result = tool.execute(nil)

    # Check the result
    result["content"].as(Array)[0]["text"].should eq("Hello, World!")
    result["isError"].should eq("false")
  end

  it "returns a default response when no callback is set" do
    schema = {
      "type"       => JSON::Any.new("object"),
      "properties" => JSON::Any.new(Hash(String, JSON::Any).new),
      "required"   => JSON::Any.new([] of JSON::Any),
    }

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)

    # Execute the tool without setting a callback
    result = tool.execute(nil)

    # Check the result
    result["content"].as(Array)[0]["text"].should eq("Tool execution not implemented for: test_tool")
    result["isError"].should eq("false")
  end
end

describe MocoPo::ToolManager do
  it "can register and retrieve tools" do
    manager = MocoPo::ToolManager.new

    schema = {
      "type"       => JSON::Any.new("object"),
      "properties" => JSON::Any.new(Hash(String, JSON::Any).new),
      "required"   => JSON::Any.new([] of JSON::Any),
    }

    tool1 = MocoPo::Tool.new("tool1", "Tool 1", schema)
    tool2 = MocoPo::Tool.new("tool2", "Tool 2", schema)

    manager.register(tool1)
    manager.register(tool2)

    manager.exists?("tool1").should be_true
    manager.exists?("tool2").should be_true
    manager.exists?("tool3").should be_false

    manager.get("tool1").should eq(tool1)
    manager.get("tool2").should eq(tool2)
    manager.get("tool3").should be_nil

    manager.list.size.should eq(2)
    manager.list.should contain(tool1)
    manager.list.should contain(tool2)
  end

  it "can remove tools" do
    manager = MocoPo::ToolManager.new

    schema = {
      "type"       => JSON::Any.new("object"),
      "properties" => JSON::Any.new(Hash(String, JSON::Any).new),
      "required"   => JSON::Any.new([] of JSON::Any),
    }

    tool = MocoPo::Tool.new("tool", "A tool", schema)

    manager.register(tool)
    manager.exists?("tool").should be_true

    manager.remove("tool")
    manager.exists?("tool").should be_false
  end
end
