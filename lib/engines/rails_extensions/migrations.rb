module ::ActiveRecord::ConnectionAdapters::SchemaStatements

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
  alias_method_chain :initialize_schema_information, :engine_additions

#  def plugin_schema_info_table_name
#    ActiveRecord::Base.wrapped_table_name Engines.schema_info_table
#  end
end

module ::Engines
  class PluginMigrator < ActiveRecord::Migrator

    # We need to be able to set the 'current' engine being migrated.
    cattr_accessor :current_plugin

    # Runs the migrations from a plugin, up (or down) to the version given
    def self.migrate_plugin(plugin, version)
      self.current_plugin = plugin
      migrate(plugin.migration_directory, version)
    end
      
    def self.schema_info_table_name
      ActiveRecord::Base.wrapped_table_name Engines.schema_info_table
    end

    # Returns the current version of the given plugin
    def self.current_version(plugin=current_plugin)
      result = ActiveRecord::Base.connection.select_one(<<-ESQL
        SELECT version FROM #{schema_info_table_name} 
        WHERE plugin_name = '#{plugin.name}'
      ESQL
      )
      if result
        result["version"].to_i
      else
        # There probably isn't an entry for this engine in the migration info table.
        # We need to create that entry, and set the version to 0
        ActiveRecord::Base.connection.execute(<<-ESQL
          INSERT INTO #{schema_info_table_name} (version, plugin_name) 
          VALUES (0,'#{plugin.name}')
        ESQL
        )      
        0
      end
    end

    def set_schema_version(version)
      ActiveRecord::Base.connection.update(<<-ESQL
        UPDATE #{self.class.schema_info_table_name} 
        SET version = #{down? ? version.to_i - 1 : version.to_i} 
        WHERE plugin_name = '#{self.current_plugin.name}'
      ESQL
      )
    end
  end
end
