require "awesome_print"
require "bundler/setup"
require File.expand_path("../lib/store.rb", __FILE__)

# raw_store = Store::LevelDB.new(File.expand_path "../test-db", __FILE__)
raw_store = Store::Memory.new
# raw_store = Store::Cached.new raw_store
obj_store = Store::ObjectStore.new raw_store
obj_store.register_module :stdlib, Store::ObjectStore::StdLib

raw_store.load

obj_store[:foo] = Set.new [:foo]
# set = obj_store[:foo]
set = obj_store.get_unserialize :foo
ap set
set << :bar
ap set

# ap raw_store.range.find_all{true}
raw_store.save