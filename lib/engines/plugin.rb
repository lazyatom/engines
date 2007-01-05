class Plugin
  
  # The name of this plugin
  attr_accessor :name

  # The directory in which this plugin is located
  attr_accessor :root
  
  # The version of this plugin
  attr_accessor :version
  
  # The about.yml information, loaded if it exists
  attr_accessor :about
  
  # Plugins can add code paths to this attribute in init.rb if they 
  # need plugin directories to be added to the load path, i.e.
  #
  #   plugin.code_paths << 'app/other_classes'
  #
  attr_accessor :code_paths
  
  # The directory in this plugin to mirror into the shared plugin 
  # public directory
  attr_accessor :public_directory
  
  # The default set of code paths which will be added to $LOAD_PATH
  # and Dependencies.load_paths
  def default_code_paths
    %w(app/controllers app/helpers app/models components)
  end
  
  # Attempts to detect the directory to use for public files.
  # If 'public' exists in the plugin, this will be used. If 'plugin' is missing
  # but 'assets' is found, 'assets' will be used.
  def default_public_directory
    %w(assets public).select { |dir| File.directory?(File.join(root, dir)) }.first || "assets"
  end
  
  def initialize(name, path)
    @name = name
    @root = path
    
    @code_paths = default_code_paths
    @public_directory = default_public_directory
    
    load_about_information
  end
  
  def load_about_information
    about_path = File.join(self.root, 'about.yml')
    if File.exist?(about_path)
      @about = YAML.load(File.open(about_path).read)
      @about.stringify_keys!
      @version = @about["version"]
    end
  end
  
  def load
    logger.debug "Plugin '#{name}': starting load."
    inject_into_load_path
    mirror_public_assets
    logger.debug "Plugin '#{name}': loaded."
  end
  
  # Adds all directories in the /app and /lib directories within the engine
  # to the load path
  def inject_into_load_path
    
    # Add relevant paths under the engine root to the load path
    code_paths.map { |p| File.join(root, p) }.each do |path| 
      if File.directory?(path)
        # Add to the load paths
        index = $LOAD_PATH.index(Engines.rails_final_load_path)
        $LOAD_PATH.insert(index + 1, path)
        $LOAD_PATH.uniq!

        # Add to the dependency system, for autoloading.
        index = ::Dependencies.load_paths.index(Engines.rails_final_dependency_load_path)
        ::Dependencies.load_paths.insert(index + 1, path)
        ::Dependencies.load_paths.uniq!
      end
    end
    
    # Add controllers to the Routing system specifically. We actually add our paths
    # to the configuration too, since routing is started AFTER plugins are. Plugins
    # which are loaded by engines specifically (i.e. because of the '*' in 
    # config.plugins) will need their paths added directly to the routing system, 
    # since at that point it has already been configured.
    plugin_controllers = File.join(root, 'app', 'controllers')
    plugin_components = File.join(root, 'components')
    if File.directory?(plugin_controllers)
      ActionController::Routing.controller_paths << plugin_controllers
      Rails.configuration.controller_paths << plugin_controllers
    end
    if File.directory?(plugin_components)
      ActionController::Routing.controller_paths << plugin_components 
      Rails.configuration.controller_paths << plugin_components
    end
    ActionController::Routing.controller_paths.uniq!
    Rails.configuration.controller_paths.uniq!
  end

  # Replicates the subdirectories under the plugins's /public or /assets directory into
  # the corresponding public directory. If both a public and assets directory is found
  # within this plugin, the public directory is used in preference.
  def mirror_public_assets
  
    begin 
      source = File.join(root, self.public_directory)
      # if there is no public directory, just return after this file
      return if !File.exist?(source)

      logger.debug "Attempting to copy plugin plugin asset files from '#{source}' to '#{Engines.public_directory}'"

      Engines.mirror_files_from(source, File.join(Engines.public_directory, name))
      
    rescue Exception => e
      logger.warn "WARNING: Couldn't create the public file structure for plugin '#{name}'; Error follows:"
      logger.warn e
    end
  end

  # return the path to this Engine's public files (with a leading '/' for use in URIs)
  def public_asset_directory
    "#{File.basename(Engines.public_directory)}/#{name}"
  end

  # The directory containing this engines migrations
  def migration_directory
    File.join(self.root, 'db', 'migrate')
  end
  
  # Returns the version number of the latest migration for this plugin
  def latest_migration
    migrations = Dir[migration_directory+"/*.rb"]
    return nil if migrations.empty?
    migrations.map { |p| File.basename(p) }.sort.last.match(/0*(\d+)\_/)[1].to_i
  end
  
  # Migrate this engine to the given version    
  def migrate(version = nil)
    Engines::PluginMigrator.migrate_plugin(self, version)
  end  
end