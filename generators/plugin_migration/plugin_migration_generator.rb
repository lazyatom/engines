class PluginMigrationGenerator < Rails::Generator::Base
  
  def initialize(runtime_args, runtime_options={})
    super
    @options = {:assigns => {}}    
    get_plugins_to_migrate(runtime_args)
    @options[:migration_file_name] = build_migration_name
    puts "migration_name: #{@options[:migration_file_name]}"
  end
  
  def manifest
    record do |m|
      m.migration_template 'plugin_migration.erb', 'db/migrate', @options
    end
  end
  
  protected
  
    def get_plugins_to_migrate(plugin_names)
      # First, grab all the plugins which exist and have migrations
      plugins_to_migrate = if plugin_names.empty?
        Rails.plugins
      else
        plugin_names.map do |name| 
          Rails.plugins[name] ? Rails.plugins[name] : raise("Cannot find the plugin '#{name}'")
        end
      end.reject! { |p| p.latest_migration.nil? }
      
      # Then find the current versions from the database    
      old_versions = {}
      plugins_to_migrate.each do |plugin|
        old_versions[plugin.name] = Engines::PluginMigrator.current_version(plugin)
      end

      # Then find the latest versions from their migration directories
      new_versions = {}      
      plugins_to_migrate.each do |plugin|
        new_versions[plugin.name] = plugin.latest_migration
      end
      
      # Remove any plugins that don't need migration
      plugins_to_migrate.map { |p| p.name }.each do 
        plugins_to_migrate.delete(Rails.plugins[name]) if old_versions[name] == new_versions[name]
      end

      @options[:assigns][:plugins] = plugins_to_migrate
      @options[:assigns][:new_versions] = new_versions
      @options[:assigns][:old_versions] = old_versions
    end

    def build_migration_name
      @plugin_versions.map { |name, version| "#{name}_to_#{version}" }.join("_and_")
    end  
end