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
  attr_accessor :public_dir
  
  def default_code_paths
    %w(app/controllers app/helpers app/models components lib)
  end
  
  # Attempts to detect the directory to use for public files.
  # If 'public' exists in the plugin, this will be used. If 'plugin' is missing
  # but 'assets' is found, 'assets' will be used.
  def default_public_dir
    %w(public assets).select { |dir| File.directory?(File.join(root, dir)) }.first || "public"
  end
  
  def initialize(name, path)
    @name = name
    @root = path
    
    @code_paths = default_code_paths
    @public_dir = default_public_dir
  end
  
  def load
    #inject_into_load_path
    #mirror_public_assets
  end
  
  # Adds all directories in the /app and /lib directories within the engine
  # to the load path
  def inject_into_load_path
      
    # Add relevant paths under the engine root to the load path
    code_paths.each do |dir| 
      path = File.join(root, dir)
      if File.directory?(path)
        # Add to the load paths
        index = $LOAD_PATH.index(Engines.rails_final_load_path)
        $LOAD_PATH.insert(index + 1, path)

        # Add to the dependency system, for autoloading.
        index = ::Dependencies.load_paths.index(Engines.rails_final_dependency_load_path)
        ::Dependencies.load_paths.insert(index + 1, path)
      end
    end
    
    # Add controllers to the Routing system specifically. TODO - is this needed?
    plugin_controllers = File.join(root, 'app', 'controllers')
    plugin_components = File.join(root, 'components')
    ActionController::Routing.controller_paths << plugin_controllers if File.directory?(plugin_controllers)
    ActionController::Routing.controller_paths << plugin_components if File.directory?(plugin_components)
  end

  # Replicates the subdirectories under the plugins's /public or /assets directory into
  # the corresponding public directory.
  #
  # TODO: include /assets
  def mirror_public_assets
  
    begin

      destination_public_dir = File.join(Engines.public_dir, name)  
      source_public_dir = File.join(root, "public")

      log.debug "Attempting to copy plugin plugin asset files from '#{source_public_dir}'"

      # if there is no public directory, just return after this file
      return if !File.exist?(source_public_dir)

      source_files = Dir[source_public_dir + "/**/*"]
      source_dirs = source_files.select { |d| File.directory?(d) }
      source_files -= source_dirs  
  
      log.debug "source dirs: #{source_dirs.inspect}"

      # Create the engine_files/<something>_engine dir if it doesn't exist
      if !File.exists?(self.destination_public_dir)
        # Create <something>_engine dir with a message
        log.debug "Creating #{self.destination_public_dir} public dir"
        FileUtils.mkdir_p(self.destination_public_dir)
      end

      # create all the directories, transforming the old path into the new path
      source_dirs.uniq.each { |dir|
        begin        
          # strip out the base path and add the result to the public path, i.e. replace 
          #   ../script/../vendor/plugins/engine_name/public/javascript
          # with
          #   engine_name/javascript
          #
          relative_dir = dir.gsub(File.join(root, "public"), name)
          target_dir = File.join(Engines.public_dir, relative_dir)
          unless File.exist?(target_dir)
            log.debug "Creating directory '#{target_dir}'"
            FileUtils.mkdir_p(target_dir)
          end
        rescue Exception => e
          raise "Could not create directory #{target_dir}: \n" + e
        end
      }

      # copy all the files, transforming the old path into the new path
      source_files.uniq.each { |file|
        begin
          # change the path from the ENGINE ROOT to the public directory root for this engine
          target = file.gsub(File.join(root, "public"), destination_public_dir)
          unless File.exist?(target) && FileUtils.identical?(file, target)
            log.debug "copying file '#{file}' to '#{target}'"
            FileUtils.cp(file, target)
          end 
        rescue Exception => e
          raise "Could not copy #{file} to #{target}: \n" + e 
        end
      }
    rescue Exception => e
      log.warn "WARNING: Couldn't create the engine public file structure for engine '#{name}'; Error follows:"
      log.warn e
    end
  end

  # return the path to this Engine's public files (with a leading '/' for use in URIs)
  def asset_base_uri
    "/#{File.basename(Engines.public_dir)}/#{name}"
  end

  # The directory containing this engines migrations
  def migration_directory
    File.join(self.root, 'db', 'migrate')
  end
  
  # Migrate this engine to the given version    
  def migrate(version = nil)
    Engines::EngineMigrator.migrate_engine(self, version)
  end  
end