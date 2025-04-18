require "../spec_helper"

describe MocoPo::Argument do
  it "can be initialized with name and type" do
    arg = MocoPo::Argument.new("name", "string")

    arg.name.should eq("name")
    arg.type.should eq("string")
    arg.required.should be_false
    arg.description.should be_nil
    arg.nested_arguments.should be_nil
    arg.item_type.should be_nil
  end

  it "can be initialized with optional parameters" do
    arg = MocoPo::Argument.new(
      name: "name",
      type: "string",
      required: true,
      description: "A name"
    )

    arg.name.should eq("name")
    arg.type.should eq("string")
    arg.required.should be_true
    arg.description.should eq("A name")
    arg.nested_arguments.should be_nil
    arg.item_type.should be_nil
  end

  it "can be initialized as an array" do
    arg = MocoPo::Argument.new(
      name: "tags",
      type: "array",
      required: false,
      description: "Tags",
      item_type: "string"
    )

    arg.name.should eq("tags")
    arg.type.should eq("array")
    arg.required.should be_false
    arg.description.should eq("Tags")
    arg.nested_arguments.should be_nil
    arg.item_type.should eq("string")
  end

  it "can be initialized as an object with nested arguments" do
    nested_args = [
      MocoPo::Argument.new("first_name", "string", true, "First name"),
      MocoPo::Argument.new("last_name", "string", true, "Last name"),
    ]

    arg = MocoPo::Argument.new(
      name: "person",
      type: "object",
      required: true,
      description: "Person information",
      nested_arguments: nested_args
    )

    arg.name.should eq("person")
    arg.type.should eq("object")
    arg.required.should be_true
    arg.description.should eq("Person information")
    arg.nested_arguments.should eq(nested_args)
    arg.item_type.should be_nil
  end

  it "converts to JSON Schema" do
    arg = MocoPo::Argument.new(
      name: "name",
      type: "string",
      required: true,
      description: "A name"
    )

    schema = arg.to_json_schema
    schema["type"].as_s.should eq("string")
    schema["description"].as_s.should eq("A name")
  end

  it "converts array arguments to JSON Schema" do
    arg = MocoPo::Argument.new(
      name: "tags",
      type: "array",
      required: false,
      description: "Tags",
      item_type: "string"
    )

    schema = arg.to_json_schema
    schema["type"].as_s.should eq("array")
    schema["description"].as_s.should eq("Tags")
    schema["items"].as_h["type"].as_s.should eq("string")
  end

  it "converts object arguments to JSON Schema" do
    nested_args = [
      MocoPo::Argument.new("first_name", "string", true, "First name"),
      MocoPo::Argument.new("last_name", "string", true, "Last name"),
    ]

    arg = MocoPo::Argument.new(
      name: "person",
      type: "object",
      required: true,
      description: "Person information",
      nested_arguments: nested_args
    )

    schema = arg.to_json_schema
    schema["type"].as_s.should eq("object")
    schema["description"].as_s.should eq("Person information")
    schema["properties"].as_h.has_key?("first_name").should be_true
    schema["properties"].as_h.has_key?("last_name").should be_true
    schema["required"].as_a.size.should eq(2)
    schema["required"].as_a.should contain(JSON::Any.new("first_name"))
    schema["required"].as_a.should contain(JSON::Any.new("last_name"))
  end
end

describe MocoPo::ArgumentBuilder do
  it "can build string arguments" do
    builder = MocoPo::ArgumentBuilder.new
    arg = builder.string("name", true, "A name")

    arg.name.should eq("name")
    arg.type.should eq("string")
    arg.required.should be_true
    arg.description.should eq("A name")

    builder.arguments.size.should eq(1)
    builder.arguments.should contain(arg)
  end

  it "can build number arguments" do
    builder = MocoPo::ArgumentBuilder.new
    arg = builder.number("age", false, "Age in years")

    arg.name.should eq("age")
    arg.type.should eq("number")
    arg.required.should be_false
    arg.description.should eq("Age in years")

    builder.arguments.size.should eq(1)
    builder.arguments.should contain(arg)
  end

  it "can build boolean arguments" do
    builder = MocoPo::ArgumentBuilder.new
    arg = builder.boolean("active", true, "Whether the user is active")

    arg.name.should eq("active")
    arg.type.should eq("boolean")
    arg.required.should be_true
    arg.description.should eq("Whether the user is active")

    builder.arguments.size.should eq(1)
    builder.arguments.should contain(arg)
  end

  it "can build array arguments" do
    builder = MocoPo::ArgumentBuilder.new
    arg = builder.array("tags", "string", false, "Tags for the item")

    arg.name.should eq("tags")
    arg.type.should eq("array")
    arg.required.should be_false
    arg.description.should eq("Tags for the item")
    arg.item_type.should eq("string")

    builder.arguments.size.should eq(1)
    builder.arguments.should contain(arg)
  end

  it "can build object arguments with nested arguments" do
    builder = MocoPo::ArgumentBuilder.new
    arg = builder.object("person", true, "Person information") do |obj|
      obj.string("first_name", true, "First name")
      obj.string("last_name", true, "Last name")
    end

    arg.name.should eq("person")
    arg.type.should eq("object")
    arg.required.should be_true
    arg.description.should eq("Person information")
    arg.nested_arguments.not_nil!.size.should eq(2)

    builder.arguments.size.should eq(1)
    builder.arguments.should contain(arg)
  end

  it "can build multiple arguments" do
    builder = MocoPo::ArgumentBuilder.new
    arg1 = builder.string("name", true, "A name")
    arg2 = builder.number("age", false, "Age in years")
    arg3 = builder.boolean("active", true, "Whether the user is active")

    builder.arguments.size.should eq(3)
    builder.arguments.should contain(arg1)
    builder.arguments.should contain(arg2)
    builder.arguments.should contain(arg3)
  end

  it "can convert to JSON Schema" do
    builder = MocoPo::ArgumentBuilder.new
    builder.string("name", true, "A name")
    builder.number("age", false, "Age in years")

    schema = builder.to_json_schema
    schema["type"].as_s.should eq("object")
    schema["properties"].as_h.has_key?("name").should be_true
    schema["properties"].as_h.has_key?("age").should be_true
    schema["required"].as_a.size.should eq(1)
    schema["required"].as_a.should contain(JSON::Any.new("name"))
    schema["required"].as_a.should_not contain(JSON::Any.new("age"))
  end
end
