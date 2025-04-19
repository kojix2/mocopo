require "../spec_helper"

describe MocoPo::Tool do
  it "can be initialized with name and description" do
    schema = {
      "type"       => "object",
      "properties" => {} of String => MocoPo::JsonValue,
      "required"   => [] of MocoPo::JsonValue,
    } of String => MocoPo::JsonValue

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)

    tool.name.should eq("test_tool")
    tool.description.should eq("A test tool")
    tool.input_schema.should eq(schema)
  end

  it "can add string arguments" do
    schema = {
      "type"       => "object",
      "properties" => {} of String => MocoPo::JsonValue,
      "required"   => [] of MocoPo::JsonValue,
    } of String => MocoPo::JsonValue

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)
    tool.argument_string("name", true, "Name to greet")

    # Check that the input schema was updated
    properties = tool.input_schema["properties"]
    properties.is_a?(Hash).should be_true
    properties_hash = properties.as(Hash)
    properties_hash.has_key?("name").should be_true

    name_prop = properties_hash["name"]
    name_prop.is_a?(Hash).should be_true
    name_hash = name_prop.as(Hash)

    name_hash["type"].should eq("string")
    name_hash["description"].should eq("Name to greet")

    required = tool.input_schema["required"]
    required.is_a?(Array).should be_true
    required_array = required.as(Array)
    required_array.should contain("name")
  end

  it "can add number arguments" do
    schema = {
      "type"       => "object",
      "properties" => {} of String => MocoPo::JsonValue,
      "required"   => [] of MocoPo::JsonValue,
    } of String => MocoPo::JsonValue

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)
    tool.argument_number("age", false, "Age in years")

    # Check that the input schema was updated
    properties = tool.input_schema["properties"]
    properties.is_a?(Hash).should be_true
    properties_hash = properties.as(Hash)
    properties_hash.has_key?("age").should be_true

    age_prop = properties_hash["age"]
    age_prop.is_a?(Hash).should be_true
    age_hash = age_prop.as(Hash)

    age_hash["type"].should eq("number")
    age_hash["description"].should eq("Age in years")

    # Check if required key exists before testing it
    if tool.input_schema.has_key?("required")
      required = tool.input_schema["required"]
      required.is_a?(Array).should be_true
      required_array = required.as(Array)
      required_array.should_not contain("age")
    end
  end

  it "can add boolean arguments" do
    schema = {
      "type"       => "object",
      "properties" => {} of String => MocoPo::JsonValue,
      "required"   => [] of MocoPo::JsonValue,
    } of String => MocoPo::JsonValue

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)
    tool.argument_boolean("active", true, "Whether the user is active")

    # Check that the input schema was updated
    properties = tool.input_schema["properties"]
    properties.is_a?(Hash).should be_true
    properties_hash = properties.as(Hash)
    properties_hash.has_key?("active").should be_true

    active_prop = properties_hash["active"]
    active_prop.is_a?(Hash).should be_true
    active_hash = active_prop.as(Hash)

    active_hash["type"].should eq("boolean")
    active_hash["description"].should eq("Whether the user is active")

    required = tool.input_schema["required"]
    required.is_a?(Array).should be_true
    required_array = required.as(Array)
    required_array.should contain("active")
  end

  it "can add array arguments" do
    schema = {
      "type"       => "object",
      "properties" => {} of String => MocoPo::JsonValue,
      "required"   => [] of MocoPo::JsonValue,
    } of String => MocoPo::JsonValue

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)
    tool.argument_array("tags", "string", false, "Tags for the item")

    # Check that the input schema was updated
    properties = tool.input_schema["properties"]
    properties.is_a?(Hash).should be_true
    properties_hash = properties.as(Hash)
    properties_hash.has_key?("tags").should be_true

    tags_prop = properties_hash["tags"]
    tags_prop.is_a?(Hash).should be_true
    tags_hash = tags_prop.as(Hash)

    tags_hash["type"].should eq("array")
    tags_hash["description"].should eq("Tags for the item")

    items = tags_hash["items"]
    items.is_a?(Hash).should be_true
    items_hash = items.as(Hash)
    items_hash["type"].should eq("string")

    # Check if required key exists before testing it
    if tool.input_schema.has_key?("required")
      required = tool.input_schema["required"]
      required.is_a?(Array).should be_true
      required_array = required.as(Array)
      required_array.should_not contain("tags")
    end
  end

  it "can add object arguments" do
    schema = {
      "type"       => "object",
      "properties" => {} of String => MocoPo::JsonValue,
      "required"   => [] of MocoPo::JsonValue,
    } of String => MocoPo::JsonValue

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)
    tool.argument_object("person", true, "Person information") do |obj|
      obj.string("first_name", true, "First name")
      obj.string("last_name", true, "Last name")
    end

    # Check that the input schema was updated
    properties = tool.input_schema["properties"]
    properties.is_a?(Hash).should be_true
    properties_hash = properties.as(Hash)
    properties_hash.has_key?("person").should be_true

    person_prop = properties_hash["person"]
    person_prop.is_a?(Hash).should be_true
    person_hash = person_prop.as(Hash)

    person_hash["type"].should eq("object")
    person_hash["description"].should eq("Person information")

    person_properties = person_hash["properties"]
    person_properties.is_a?(Hash).should be_true
    person_properties_hash = person_properties.as(Hash)
    person_properties_hash.has_key?("first_name").should be_true
    person_properties_hash.has_key?("last_name").should be_true

    required = tool.input_schema["required"]
    required.is_a?(Array).should be_true
    required_array = required.as(Array)
    required_array.should contain("person")
  end

  it "can set and execute a callback" do
    schema = {
      "type"       => "object",
      "properties" => {} of String => MocoPo::JsonValue,
      "required"   => [] of MocoPo::JsonValue,
    } of String => MocoPo::JsonValue

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
    content = result["content"]
    content.is_a?(Array).should be_true
    content_array = content.as(Array)
    content_array.size.should eq(1)

    first_item = content_array[0]
    first_item.is_a?(Hash).should be_true
    first_item_hash = first_item.as(Hash)
    first_item_hash["text"].should eq("Hello, World!")

    result["isError"].should eq("false")
  end

  it "returns a default response when no callback is set" do
    schema = {
      "type"       => "object",
      "properties" => {} of String => MocoPo::JsonValue,
      "required"   => [] of MocoPo::JsonValue,
    } of String => MocoPo::JsonValue

    tool = MocoPo::Tool.new("test_tool", "A test tool", schema)

    # Execute the tool without setting a callback
    result = tool.execute(nil)

    # Check the result
    content = result["content"]
    content.is_a?(Array).should be_true
    content_array = content.as(Array)
    content_array.size.should eq(1)

    first_item = content_array[0]
    first_item.is_a?(Hash).should be_true
    first_item_hash = first_item.as(Hash)
    first_item_hash["text"].should eq("Tool execution not implemented for: test_tool")

    result["isError"].should eq("false")
  end
end

describe MocoPo::ToolManager do
  it "can register and retrieve tools" do
    manager = MocoPo::ToolManager.new

    schema = {
      "type"       => "object",
      "properties" => {} of String => MocoPo::JsonValue,
      "required"   => [] of MocoPo::JsonValue,
    } of String => MocoPo::JsonValue

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
      "type"       => "object",
      "properties" => {} of String => MocoPo::JsonValue,
      "required"   => [] of MocoPo::JsonValue,
    } of String => MocoPo::JsonValue

    tool = MocoPo::Tool.new("tool", "A tool", schema)

    manager.register(tool)
    manager.exists?("tool").should be_true

    manager.remove("tool")
    manager.exists?("tool").should be_false
  end
end
