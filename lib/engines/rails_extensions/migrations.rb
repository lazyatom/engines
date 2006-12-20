require "engines/plugin_migrator"

module Engines::RailsExtensions::Migrations
  def self.included(base)
    base.class_eval { alias_method_chain :initialize_schema_information, :engine_additions }
  end

  # Create the schema tables, and ensure that the plugin schema table
  # is also initialized
  def initialize_schema_information_with_engine_additions
    initialize_schema_information_without_engine_additions
    
    # create the plugin schema stuff.    
    begin
      execute <<-ESQL
        CREATE TABLE #{Engines::PluginMigrator.schema_info_table_name} 
          (plugin_name #{type_to_sql(:string)}, version #{type_to_sql(:integer)})
      ESQL
    rescue ActiveRecord::StatementInvalid
      # Schema has been initialized
    end
  end
end

::ActiveRecord::ConnectionAdapters::SchemaStatements.send(:include, Engines::RailsExtensions::Migrations)
