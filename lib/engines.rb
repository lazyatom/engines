require 'engines/plugin_list'
require 'engines/plugin'

module ::Engines
  # The name of the public directory to mirror public engine assets into
  mattr_accessor :public_directory

  # The table in which to store plugin schema information
  mattr_accessor :schema_info_table

  # a reference to the currently-loaded plugin. This is present to support
  # legacy engines; it's preferred to use Rails.plugins[name] in your plugin's
  # init.rb file in order to get the Plugin instance.
  mattr_accessor :current  
  
  # A reference to the current Rails::Initializer instance
  mattr_accessor :rails_initializer
  
  private

  # A memo of the bottom of Rails' default load path
  mattr_accessor :rails_final_load_path
  # A memo of the bottom of Rails Dependencies load path
  mattr_accessor :rails_final_dependency_load_path
  
  public
    
  def self.init
    # First, determine if we're running in legacy mode
    @legacy_support = self.const_defined?(:LegacySupport) && LegacySupport

    self.public_directory = default_public_directory
    self.schema_info_table = default_schema_info_table
    @load_all_plugins = false    
    
    store_load_path_marker
    store_dependency_load_path_marker
    
    initialize_plugin_list
    initialize_base_public_directory    
  end

  # Whether or not to load legacy 'engines' (with init_engine.rb) as if they were plugins
  # You can enable legacy support by defining the LegacySupport constant
  # in the Engines module before Rails loads, i.e. at the *top* of environment.rb,
  # add:
  # 
  #   module Engines
  #     LegacySupport = true
  #   end
  #
  def self.legacy_support?
    @legacy_support
  end

  # This is set to true if Engines detects a "*" at the end of
  # the config.plugins array.  
  def self.load_all_plugins?
    @load_all_plugins
  end
    

  # TODO: how will this affect upgrades?
  # could just get folks to manually rename the table. Or provide an upgrade
  # migration...?
  def self.default_schema_info_table
    "plugin_schema_info"
  end

  # The default plugin assets directory, stored under RAILS_ROOT/public.
  # In legacy support mode, this is RAILS_ROOT/public/engine_files;
  # Otherwise, it's RAILS_ROOT/public/plugin_assets.
  def self.default_public_directory
    File.join(RAILS_ROOT, 'public', self.legacy_support? ? 'engine_files' : 'plugin_assets')
  end

  # Stores a record of the last path with Rails added to the load path.
  # We need this to ensure that we place our additions to the load path *after*
  # all Rails' defaults
  def self.store_load_path_marker
    self.rails_final_load_path = $LOAD_PATH.last
    puts "Rails final load path: #{self.rails_final_load_path}"
  end

  # Store a record of the last entry in the dependency system's load path.
  # We need this to ensure that we place our additions to the load path *after*
  # all Rails' defaults
  def self.store_dependency_load_path_marker
    self.rails_final_dependency_load_path = ::Dependencies.load_paths.last
    puts "Rails final dependency load path: #{self.rails_final_dependency_load_path}"
  end

  # Creates the PluginList which holds all loaded plugins. This list also reflects
  # the load order of any plugins which engines was responsible for loading, i.e.
  # any loaded via Engines.start, and any loaded as a result of config.plugins
  # having a "*" value after engines.
  # Note that the load order of any plugins loaded *before* engines is not reflected
  # in this list.
  def self.initialize_plugin_list
    Rails.plugins ||= PluginList.new
    Rails.plugins << Plugin.new("engines", File.join(self.find_plugin_path("engines"), "engines"))
  end
  
  def self.initialize_base_public_directory
    if !File.exist?(self.public_directory)
      # create the public/engines directory, with a warning message in it.
      #log.debug "Creating public engine files directory '#{@public_dir}'"
      FileUtils.mkdir(self.public_directory)
      message = %{Files in this directory are automatically generated from your Rails Engines.
They are copied from the 'public' directories of each engine into this directory
each time Rails starts (server, console... any time 'start_engine' is called).
Any edits you make will NOT persist across the next server restart; instead you
should edit the files within the <engine_name>/public/ directory itself.}
      target = File.join(public_directory, "README")
      File.open(target, 'w') { |f| f.puts(message) } unless File.exist?(target)
    end
  end


  #-
  # The following code is called once all plugins are loaded, and Rails is almost
  # finished initialization
  #+

  # Once the Rails Initializer has finished, the engines plugin takes over
  # and performs any post-processing tasks it may have, including:
  #
  # * loading any remaining plugins if config.plugins ended with a '*'
  # * ... nothing else right now.
  #
  def self.after_initialize
    # if the patch in http://dev.rubyonrails.org/ticket/6851 is approved, this
    # is no longer necessary.
    enginize_previously_loaded_plugins
    
    load_remaining_plugins
  end
  
  # Load any plugins which *were* specifed in config.plugins, but which
  # Rails::Initializer skipped because the engines plugin hadn't been loaded
  # yet.
  def self.enginize_previously_loaded_plugins
    Rails.configuration.plugins.each do |name|
      plugin_path = File.join(self.find_plugin_path(name), name)
      unless Rails.plugins[name]
        plugin = Plugin.new(name, plugin_path)
        puts "enginizing plugin: #{plugin.name} from #{plugin_path}"
        plugin.load # injects the extra directories into the load path, and mirrors public files
        Rails.plugins << plugin
      end
    end
  end
  
  # Loads all plugins using the Rails::Initializer extensions
  def self.load_remaining_plugins
    if Rails.configuration.plugins.last == "*"
      puts "loading remaining plugins from #{Rails.configuration.plugin_paths.inspect}"
      @load_all_plugins = true
      # now call the original method. this will actually try to load ALL plugins
      # again, but any that have already been loaded will be ignored.
      rails_initializer.load_plugins 
    end
  end
  
  
  
  #-
  # helper methods to find and deal with plugin paths and names
  #+
  
  def self.find_plugin_path(name)
    Rails.configuration.plugin_paths.find do |path|
      File.exist?(File.join(path, name))
    end    
  end
  
  # Also appears in Rails::Initializer extensions
  def self.plugin_name(path)
    File.basename(path)
  end
end  