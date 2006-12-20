#require 'active_record/migrations'

class Engines::PluginMigrator < ActiveRecord::Migrator

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
