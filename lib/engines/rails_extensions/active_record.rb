module Engines::RailsExtensions::ActiveRecord
  # NOTE: Currently the Migrations system will ALWAYS wrap given table names
  # in the prefix/suffix, so any table name set via config(:table_name), for instance
  # will always get wrapped in the process of migration. For this reason, whatever
  # value you give to the config will be wrapped when set_table_name is used in the
  # model.
  #
  # This method is onl
  def wrapped_table_name(name)
    table_name_prefix + name + table_name_suffix
  end
end

::ActiveRecord::Base.extend(Engines::RailsExtensions::ActiveRecord)

# Set ActiveRecord to ignore the plugin schema table by default
::ActiveRecord::SchemaDumper.ignore_tables << Engines.schema_info_table