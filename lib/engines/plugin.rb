class Plugin
  
  # The name of this plugin
  attr_accessor :name

  # The directory in which this plugin is located
  attr_accessor :root
  
  # The version of this plugin
  attr_accessor :version
  
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
    
    # Add controllers to the Routing system specifically. TODO - is this needed?
    plugin_controllers = File.join(root, 'app', 'controllers')
    plugin_components = File.join(root, 'components')
    ActionController::Routing.controller_paths << plugin_controllers if File.directory?(plugin_controllers)
    ActionController::Routing.controller_paths << plugin_components if File.directory?(plugin_components)
    ActionController::Routing.controller_paths.uniq!
  end

  # Replicates the subdirectories under the plugins's /public or /assets directory into
  # the corresponding public directory. If both a public and assets directory is found
  # within this plugin, the public directory is used in preference.
  def mirror_public_assets
  
    begin

      #destination = File.join(Engines.public_directory, name)  
      source = File.join(root, self.public_directory)

      # if there is no public directory, just return after this file
      return if !File.exist?(source)

      logger.debug "Attempting to copy plugin plugin asset files from '#{source}' to '#{Engines.public_directory}'"

      source_files = Dir[source + "/**/*"]
      source_dirs = source_files.select { |d| File.directory?(d) }
      source_files -= source_dirs  
      source_dirs.map! { |d| File.join(name, d.gsub(source, '')) }
      source_files.map! { |f| File.join(name, f.gsub(source, '')) }
  
      logger.debug "source dirs: #{source_dirs.inspect}"
      logger.debug "source files: #{source_files.inspect}"

      # create all the directories, transforming the old path into the new path
      source_dirs.uniq.each { |dir|
        begin        
          target_dir = File.join(Engines.public_directory, dir)
          unless File.exist?(target_dir)
            logger.debug "Creating directory '#{target_dir}'"
            FileUtils.mkdir_p(target_dir)
          end
        rescue Exception => e
          raise "Could not create directory #{target_dir}: \n" + e
        end
      }

      source_files.uniq.each { |file|
        begin
          src = File.join(self.root, self.public_directory, file.gsub(self.name, ''))
          target = File.join(Engines.public_directory, file)
          unless File.exist?(target) && FileUtils.identical?(src, target)
            logger.debug "copying file '#{src}' to '#{target}'"
            FileUtils.cp(src, target)
          end 
        rescue Exception => e
          raise "Could not copy #{file} to #{target}: \n" + e 
        end
      }
    rescue Exception => e
      logger.warn "WARNING: Couldn't create the engine public file structure for engine '#{name}'; Error follows:"
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