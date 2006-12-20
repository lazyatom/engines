class PluginMigrationGenerator < Rails::Generator::Base
  
  def initialize(runtime_args, runtime_options={})
    super
    @options = {:assigns => {}}
    
    ensure_plugin_schema_table_exists
    get_plugins_to_migrate(runtime_args)
    
    if @plugins_to_migrate.empty?
      puts "All plugins are migrated to their latest versions"
      exit(0)
    end

    @options[:migration_file_name] = build_migration_name
    @options[:assigns][:class_name] = build_migration_name.classify
  end
  
  def manifest
    record do |m|
      m.migration_template 'plugin_migration.erb', 'db/migrate', @options
    end
  end
  
  protected
  
    def ensure_plugin_schema_table_exists
      ActiveRecord::Base.connection.initialize_schema_information
    end
  
    def get_plugins_to_migrate(plugin_names)
      
      #puts "plugin_names: #{plugin_names.inspect}"
      
      # First, grab all the plugins which exist and have migrations
      @plugins_to_migrate = if plugin_names.empty?
        Rails.plugins
      else
        plugin_names.map do |name| 
          Rails.plugins[name] ? Rails.plugins[name] : raise("Cannot find the plugin '#{name}'")
        end
      end
      
      #puts "plugin_to_migate: #{@plugins_to_migrate.inspect}"
      
      @plugins_to_migrate.reject! { |p| p.latest_migration.nil? }
      
      # Then find the current versions from the database    
      @current_versions = {}
      @plugins_to_migrate.each do |plugin|
        @current_versions[plugin.name] = Engines::PluginMigrator.current_version(plugin)
      end

      # Then find the latest versions from their migration directories
      @new_versions = {}      
      @plugins_to_migrate.each do |plugin|
        @new_versions[plugin.name] = plugin.latest_migration
      end
      
      # Remove any plugins that don't need migration
      @plugins_to_migrate.map { |p| p.name }.each do |name|
        @plugins_to_migrate.delete(Rails.plugins[name]) if @current_versions[name] == @new_versions[name]
      end
      
      @options[:assigns][:plugins] = @plugins_to_migrate
      @options[:assigns][:new_versions] = @new_versions
      @options[:assigns][:current_versions] = @current_versions
    end

    def build_migration_name
      @plugins_to_migrate.map do |plugin| 
        "#{plugin.name}_to_version_#{@new_versions[plugin.name]}" 
      end.join("_and_")
    end  
end