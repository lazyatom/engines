class UpgradeEnginesTo12 < ActiveRecord::Migration
  def self.up
    rename_table(:engine_schema_info, :plugin_schema_info) rescue nil
  end

  def self.down
    rename_table(:plugin_schema_info, :engine_schema_info) rescue nil
  end
end
