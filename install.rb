# TODO
#
#  * add upgrade path from engines 1.1.x

puts <<-END_OF_MESSAGE
Welcome to the engines plugin 1.2 release.

Some of the internals have changed, so you'll want to take particular note of the following:

All plugins can act like engines now
Init_engine.rb is gone. Replace it with init.rb.
Rename engine_schema_info -> plugin_schema_info
END_OF_MESSAGE
