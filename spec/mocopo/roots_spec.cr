require "../spec_helper"
require "file_utils"

describe MocoPo::Root do
  # Create a temporary directory for testing
  temp_dir = File.join(Dir.tempdir, "mocopo_test_#{Random.new.hex(8)}")
  FileUtils.mkdir_p(temp_dir)

  # Create a test file
  test_file_path = File.join(temp_dir, "test.txt")
  File.write(test_file_path, "Hello, world!")

  # Create a test directory
  test_dir_path = File.join(temp_dir, "test_dir")
  FileUtils.mkdir_p(test_dir_path)

  # Create a test file in the test directory
  test_nested_file_path = File.join(test_dir_path, "nested.txt")
  File.write(test_nested_file_path, "Nested file content")

  # Clean up after tests
  Spec.after_suite do
    FileUtils.rm_rf(temp_dir)
  end

  it "can be created with valid parameters" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    root.id.should eq("test")
    root.name.should eq("Test Root")
    root.description.should eq("A test root")
    root.path.should eq(temp_dir)
    root.read_only.should be_true
  end

  it "can be created with read-only flag set to false" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir, false)
    root.read_only.should be_false
  end

  it "raises an error if the path does not exist" do
    expect_raises(ArgumentError) do
      MocoPo::Root.new("test", "Test Root", "A test root", "/path/does/not/exist")
    end
  end

  it "raises an error if the path is not absolute" do
    expect_raises(ArgumentError) do
      MocoPo::Root.new("test", "Test Root", "A test root", "relative/path")
    end
  end

  it "can convert to JSON-compatible Hash" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    json = root.to_json_object
    json["id"].should eq("test")
    json["name"].should eq("Test Root")
    json["description"].should eq("A test root")
    json["readOnly"].should be_true
  end

  it "can check if a path is within the root" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    root.contains?(test_file_path).should be_true
    root.contains?(test_dir_path).should be_true
    root.contains?(test_nested_file_path).should be_true
    root.contains?("/path/does/not/exist").should be_false
  end

  it "can get the relative path from the root" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    root.relative_path(test_file_path).should eq("/test.txt")
    root.relative_path(test_dir_path).should eq("/test_dir")
    root.relative_path(test_nested_file_path).should eq("/test_dir/nested.txt")
  end

  it "raises an error if the path is not within the root" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    expect_raises(ArgumentError) do
      root.relative_path("/path/does/not/exist")
    end
  end

  it "can get the absolute path from a relative path" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    root.absolute_path("/test.txt").should eq(test_file_path)
    root.absolute_path("/test_dir").should eq(test_dir_path)
    root.absolute_path("/test_dir/nested.txt").should eq(test_nested_file_path)
  end

  it "can check if a file exists" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    root.file_exists?("/test.txt").should be_true
    root.file_exists?("/test_dir/nested.txt").should be_true
    root.file_exists?("/does/not/exist.txt").should be_false
    root.file_exists?("/test_dir").should be_false
  end

  it "can check if a directory exists" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    root.directory_exists?("/test_dir").should be_true
    root.directory_exists?("/test.txt").should be_false
    root.directory_exists?("/does/not/exist").should be_false
  end

  it "can list files in a directory" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    files = root.list_directory("/")
    files.should contain("test.txt")
    files.should contain("test_dir")

    files = root.list_directory("/test_dir")
    files.should contain("nested.txt")
  end

  it "raises an error if the directory does not exist" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    expect_raises(ArgumentError) do
      root.list_directory("/does/not/exist")
    end
  end

  it "can read a file" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    root.read_file("/test.txt").should eq("Hello, world!")
    root.read_file("/test_dir/nested.txt").should eq("Nested file content")
  end

  it "raises an error if the file does not exist" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    expect_raises(ArgumentError) do
      root.read_file("/does/not/exist.txt")
    end
  end

  it "can write a file if not read-only" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir, false)
    root.write_file("/new_file.txt", "New file content")
    root.file_exists?("/new_file.txt").should be_true
    root.read_file("/new_file.txt").should eq("New file content")
  end

  it "raises an error if trying to write a file when read-only" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    expect_raises(ArgumentError) do
      root.write_file("/new_file.txt", "New file content")
    end
  end

  it "can delete a file if not read-only" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir, false)
    delete_file_path = File.join(temp_dir, "to_delete.txt")
    File.write(delete_file_path, "Delete me")
    root.file_exists?("/to_delete.txt").should be_true
    root.delete_file("/to_delete.txt")
    root.file_exists?("/to_delete.txt").should be_false
  end

  it "raises an error if trying to delete a file when read-only" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    delete_file_path = File.join(temp_dir, "to_delete.txt")
    File.write(delete_file_path, "Delete me")
    expect_raises(ArgumentError) do
      root.delete_file("/to_delete.txt")
    end
  end

  it "raises an error if trying to delete a file that does not exist" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir, false)
    expect_raises(ArgumentError) do
      root.delete_file("/does/not/exist.txt")
    end
  end

  it "can create a directory if not read-only" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir, false)
    root.create_directory("/new_dir")
    root.directory_exists?("/new_dir").should be_true
  end

  it "raises an error if trying to create a directory when read-only" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    expect_raises(ArgumentError) do
      root.create_directory("/new_dir")
    end
  end

  it "can delete a directory if not read-only" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir, false)
    delete_dir_path = File.join(temp_dir, "to_delete_dir")
    FileUtils.mkdir_p(delete_dir_path)
    root.directory_exists?("/to_delete_dir").should be_true
    root.delete_directory("/to_delete_dir")
    root.directory_exists?("/to_delete_dir").should be_false
  end

  it "raises an error if trying to delete a directory when read-only" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    delete_dir_path = File.join(temp_dir, "to_delete_dir")
    FileUtils.mkdir_p(delete_dir_path)
    expect_raises(ArgumentError) do
      root.delete_directory("/to_delete_dir")
    end
  end

  it "raises an error if trying to delete a directory that does not exist" do
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir, false)
    expect_raises(ArgumentError) do
      root.delete_directory("/does/not/exist")
    end
  end
end

describe MocoPo::RootManager do
  # Create a temporary directory for testing
  temp_dir = File.join(Dir.tempdir, "mocopo_test_#{Random.new.hex(8)}")
  FileUtils.mkdir_p(temp_dir)

  # Create a test file
  test_file_path = File.join(temp_dir, "test.txt")
  File.write(test_file_path, "Hello, world!")

  # Clean up after tests
  Spec.after_suite do
    FileUtils.rm_rf(temp_dir)
  end

  it "can register a root" do
    manager = MocoPo::RootManager.new
    root = MocoPo::Root.new("test", "Test Root", "A test root", temp_dir)
    manager.register(root)
    manager.exists?("test").should be_true
    manager.get("test").should eq(root)
  end

  it "can register a root with parameters" do
    manager = MocoPo::RootManager.new
    root = manager.register("test", "Test Root", "A test root", temp_dir)
    manager.exists?("test").should be_true
    manager.get("test").should eq(root)
  end

  it "raises an error if a root with the same ID already exists" do
    manager = MocoPo::RootManager.new
    manager.register("test", "Test Root", "A test root", temp_dir)
    expect_raises(ArgumentError) do
      manager.register("test", "Another Test Root", "Another test root", temp_dir)
    end
  end

  it "can unregister a root" do
    manager = MocoPo::RootManager.new
    manager.register("test", "Test Root", "A test root", temp_dir)
    manager.exists?("test").should be_true
    manager.unregister("test")
    manager.exists?("test").should be_false
  end

  it "raises an error if trying to unregister a root that does not exist" do
    manager = MocoPo::RootManager.new
    expect_raises(ArgumentError) do
      manager.unregister("does_not_exist")
    end
  end

  it "can check if a root exists" do
    manager = MocoPo::RootManager.new
    manager.exists?("test").should be_false
    manager.register("test", "Test Root", "A test root", temp_dir)
    manager.exists?("test").should be_true
  end

  it "can get a root" do
    manager = MocoPo::RootManager.new
    manager.get("test").should be_nil
    root = manager.register("test", "Test Root", "A test root", temp_dir)
    manager.get("test").should eq(root)
  end

  it "can list all roots" do
    manager = MocoPo::RootManager.new
    manager.list.should be_empty
    root1 = manager.register("test1", "Test Root 1", "A test root", temp_dir)
    root2 = manager.register("test2", "Test Root 2", "Another test root", temp_dir)
    roots = manager.list
    roots.size.should eq(2)
    roots.should contain(root1)
    roots.should contain(root2)
  end

  it "can find a root that contains a path" do
    manager = MocoPo::RootManager.new
    root = manager.register("test", "Test Root", "A test root", temp_dir)
    manager.find_root_for_path(test_file_path).should eq(root)
    manager.find_root_for_path("/path/does/not/exist").should be_nil
  end

  it "can get the root and relative path for a path" do
    manager = MocoPo::RootManager.new
    root = manager.register("test", "Test Root", "A test root", temp_dir)
    result = manager.get_root_and_relative_path(test_file_path)
    result.should_not be_nil
    result_root, relative_path = result.not_nil!
    result_root.should eq(root)
    relative_path.should eq("/test.txt")
    manager.get_root_and_relative_path("/path/does/not/exist").should be_nil
  end
end

describe MocoPo::RootFileInfo do
  # Create a temporary directory for testing
  temp_dir = File.join(Dir.tempdir, "mocopo_test_#{Random.new.hex(8)}")
  FileUtils.mkdir_p(temp_dir)

  # Create a test file
  test_file_path = File.join(temp_dir, "test.txt")
  File.write(test_file_path, "Hello, world!")

  # Create a test directory
  test_dir_path = File.join(temp_dir, "test_dir")
  FileUtils.mkdir_p(test_dir_path)

  # Clean up after tests
  Spec.after_suite do
    FileUtils.rm_rf(temp_dir)
  end

  it "can be created with valid parameters" do
    file_info = MocoPo::RootFileInfo.new("test.txt", "/test.txt", "file", 13, Time.utc)
    file_info.name.should eq("test.txt")
    file_info.path.should eq("/test.txt")
    file_info.type.should eq("file")
    file_info.size.should eq(13)
    file_info.modified.should be_a(Time)
  end

  it "can convert to JSON-compatible Hash" do
    time = Time.utc
    file_info = MocoPo::RootFileInfo.new("test.txt", "/test.txt", "file", 13, time)
    json = file_info.to_json_object
    json["name"].should eq("test.txt")
    json["path"].should eq("/test.txt")
    json["type"].should eq("file")
    json["size"].should eq(13)
    json["modified"].should eq(time.to_unix)
  end

  it "can be created from a file path" do
    file_info = MocoPo::RootFileInfo.from_file(test_file_path, "/test.txt")
    file_info.name.should eq("test.txt")
    file_info.path.should eq("/test.txt")
    file_info.type.should eq("file")
    file_info.size.should eq(13)
    file_info.modified.should be_a(Time)

    dir_info = MocoPo::RootFileInfo.from_file(test_dir_path, "/test_dir")
    dir_info.name.should eq("test_dir")
    dir_info.path.should eq("/test_dir")
    dir_info.type.should eq("directory")
    dir_info.modified.should be_a(Time)
  end
end

describe MocoPo::RootDirectoryListing do
  it "can be created with valid parameters" do
    files = [
      MocoPo::RootFileInfo.new("test.txt", "/test.txt", "file", 13, Time.utc),
      MocoPo::RootFileInfo.new("test_dir", "/test_dir", "directory", 0, Time.utc),
    ]
    listing = MocoPo::RootDirectoryListing.new("test", "/", files)
    listing.root_id.should eq("test")
    listing.path.should eq("/")
    listing.files.size.should eq(2)
    listing.files[0].name.should eq("test.txt")
    listing.files[1].name.should eq("test_dir")
  end

  it "can convert to JSON-compatible Hash" do
    files = [
      MocoPo::RootFileInfo.new("test.txt", "/test.txt", "file", 13, Time.utc),
      MocoPo::RootFileInfo.new("test_dir", "/test_dir", "directory", 0, Time.utc),
    ]
    listing = MocoPo::RootDirectoryListing.new("test", "/", files)
    json = listing.to_json_object
    json["rootId"].should eq("test")
    json["path"].should eq("/")
    json["files"].should be_a(Array(MocoPo::JsonValue))
    json["files"].as(Array).size.should eq(2)
    json["files"].as(Array)[0].as(Hash)["name"].should eq("test.txt")
    json["files"].as(Array)[1].as(Hash)["name"].should eq("test_dir")
  end
end

describe MocoPo::RootFileContent do
  it "can be created with valid parameters" do
    content = MocoPo::RootFileContent.new("test", "/test.txt", "Hello, world!")
    content.root_id.should eq("test")
    content.path.should eq("/test.txt")
    content.content.should eq("Hello, world!")
  end

  it "can convert to JSON-compatible Hash" do
    content = MocoPo::RootFileContent.new("test", "/test.txt", "Hello, world!")
    json = content.to_json_object
    json["rootId"].should eq("test")
    json["path"].should eq("/test.txt")
    json["content"].should eq("Hello, world!")
  end
end

describe MocoPo::Server do
  # Create a temporary directory for testing
  temp_dir = File.join(Dir.tempdir, "mocopo_test_#{Random.new.hex(8)}")
  FileUtils.mkdir_p(temp_dir)

  # Clean up after tests
  Spec.after_suite do
    FileUtils.rm_rf(temp_dir)
  end

  it "initializes a root manager" do
    server = MocoPo::Server.new("test", "1.0", false)
    server.root_manager.should be_a(MocoPo::RootManager)
  end

  it "can register a root" do
    server = MocoPo::Server.new("test", "1.0", false)
    root = server.register_root("test", "Test Root", "A test root", temp_dir)
    server.root_manager.exists?("test").should be_true
    server.root_manager.get("test").should eq(root)
  end
end

describe MocoPo::RootsHandler do
  # Create a temporary directory for testing
  temp_dir = File.join(Dir.tempdir, "mocopo_test_#{Random.new.hex(8)}")
  FileUtils.mkdir_p(temp_dir)

  # Create a test file
  test_file_path = File.join(temp_dir, "test.txt")
  File.write(test_file_path, "Hello, world!")

  # Create a test directory
  test_dir_path = File.join(temp_dir, "test_dir")
  FileUtils.mkdir_p(test_dir_path)

  # Create a test file in the test directory
  test_nested_file_path = File.join(test_dir_path, "nested.txt")
  File.write(test_nested_file_path, "Nested file content")

  # Clean up after tests
  Spec.after_suite do
    FileUtils.rm_rf(temp_dir)
  end

  it "handles roots/list requests" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::RootsHandler.new(server)
    server.register_root("test", "Test Root", "A test root", temp_dir)

    response = handler.handle_list(1, nil)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil
    result = response["result"]
    result.should be_a(Hash(String, MocoPo::JsonValue))
    result.as(Hash)["roots"]?.should_not be_nil
    roots = result.as(Hash)["roots"]
    roots.should be_a(Array(MocoPo::JsonValue))
    roots.as(Array).size.should eq(1)
    roots.as(Array)[0].as(Hash)["id"].should eq("test")
  end

  it "handles roots/listDirectory requests" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::RootsHandler.new(server)
    server.register_root("test", "Test Root", "A test root", temp_dir)

    params = {
      "rootId" => "test",
      "path"   => "/",
    } of String => MocoPo::JsonValue

    response = handler.handle_list_directory(1, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil
    result = response["result"]
    result.should be_a(Hash(String, MocoPo::JsonValue))
    result.as(Hash)["rootId"].should eq("test")
    result.as(Hash)["path"].should eq("/")
    result.as(Hash)["files"].should be_a(Array(MocoPo::JsonValue))
    files = result.as(Hash)["files"].as(Array)
    files.size.should be >= 2
    file_names = files.map { |f| f.as(Hash)["name"].as(String) }
    file_names.should contain("test.txt")
    file_names.should contain("test_dir")
  end

  it "handles roots/readFile requests" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::RootsHandler.new(server)
    server.register_root("test", "Test Root", "A test root", temp_dir)

    params = {
      "rootId" => "test",
      "path"   => "/test.txt",
    } of String => MocoPo::JsonValue

    response = handler.handle_read_file(1, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil
    result = response["result"]
    result.should be_a(Hash(String, MocoPo::JsonValue))
    result.as(Hash)["rootId"].should eq("test")
    result.as(Hash)["path"].should eq("/test.txt")
    result.as(Hash)["content"].should eq("Hello, world!")
  end

  it "handles roots/writeFile requests" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::RootsHandler.new(server)
    server.register_root("test", "Test Root", "A test root", temp_dir, false)

    params = {
      "rootId"  => "test",
      "path"    => "/new_file.txt",
      "content" => "New file content",
    } of String => MocoPo::JsonValue

    response = handler.handle_write_file(1, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil

    # Check that the file was created
    File.exists?(File.join(temp_dir, "new_file.txt")).should be_true
    File.read(File.join(temp_dir, "new_file.txt")).should eq("New file content")
  end

  it "handles roots/deleteFile requests" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::RootsHandler.new(server)
    server.register_root("test", "Test Root", "A test root", temp_dir, false)

    # Create a file to delete
    delete_file_path = File.join(temp_dir, "to_delete.txt")
    File.write(delete_file_path, "Delete me")

    params = {
      "rootId" => "test",
      "path"   => "/to_delete.txt",
    } of String => MocoPo::JsonValue

    response = handler.handle_delete_file(1, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil

    # Check that the file was deleted
    File.exists?(delete_file_path).should be_false
  end

  it "handles roots/createDirectory requests" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::RootsHandler.new(server)
    server.register_root("test", "Test Root", "A test root", temp_dir, false)

    params = {
      "rootId" => "test",
      "path"   => "/new_dir",
    } of String => MocoPo::JsonValue

    response = handler.handle_create_directory(1, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil

    # Check that the directory was created
    Dir.exists?(File.join(temp_dir, "new_dir")).should be_true
  end

  it "handles roots/deleteDirectory requests" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::RootsHandler.new(server)
    server.register_root("test", "Test Root", "A test root", temp_dir, false)

    # Create a directory to delete
    delete_dir_path = File.join(temp_dir, "to_delete_dir")
    FileUtils.mkdir_p(delete_dir_path)

    params = {
      "rootId" => "test",
      "path"   => "/to_delete_dir",
    } of String => MocoPo::JsonValue

    response = handler.handle_delete_directory(1, params)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["result"]?.should_not be_nil

    # Check that the directory was deleted
    Dir.exists?(delete_dir_path).should be_false
  end

  it "handles unknown methods" do
    server = MocoPo::Server.new("test", "1.0", false)
    handler = MocoPo::RootsHandler.new(server)

    response = handler.handle(1, "unknown", nil)
    response.should be_a(Hash(String, MocoPo::JsonValue))
    response["error"]?.should_not be_nil
    error = response["error"]
    error.should be_a(Hash(String, MocoPo::JsonValue))
    error.as(Hash)["code"].should eq(-32601)
  end
end
