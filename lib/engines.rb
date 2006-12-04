module ::Engines
  # The name of the public directory to mirror public engine assets into
  mattr_accessor :public_dir

  # The table in which to store plugin schema information
  mattr_accessor :schema_info_table

  # Whether or not to load legacy 'engines' (with init.rb) as if they were plugins
  # You can enable legacy support by defining the LegacySupport constant
  # in the Engines module before Rails loads, i.e. at the *top* of environment.rb,
  # add:
  # 
  #   module Engines
  #     LegacySupport = true
  #   end
  #
  mattr_accessor :legacy_support
  
  # a reference to the currently-loaded plugin. # TODO - remove this?
  mattr_accessor :current  

  # For holding the rails configuration object
  mattr_accessor :rails_config
  
  # A reference to the current Rails::Initializer instance
  mattr_accessor :rails_initializer
  
  # This is set to true if Engines detects a "*" at the end of
  # the config.plugins array.
  mattr_accessor :load_all_plugins

  private

  # A memo of the bottom of Rails' default load path
  mattr_accessor :rails_final_load_path
  # A memo of the bottom of Rails Dependencies load path
  mattr_accessor :rails_final_dependency_load_path
  
  public
    
  def self.init
    self.schema_info_table = default_schema_info_table
    self.legacy_support = self.const_defined?(:LegacySupport) && LegacySupport
    
    store_load_path_marker
    store_dependency_load_path_marker
    
    #initialize_base_public_directory
  end

  # TODO: how will this affect upgrades?
  # could just get folks to manually rename the table. Or provide an upgrade
  # migration...?
  def self.default_schema_info_table
    "plugin_schema_info"
  end

  # Stores a record of the last path with Rails added to the load path
  def self.store_load_path_marker
    self.rails_final_load_path = $LOAD_PATH.last
    #log.debug "Rails final load path: #{self.rails_final_load_path}"
  end

  def self.store_dependency_load_path_marker
    self.rails_final_dependency_load_path = ::Dependencies.load_paths.last
    #log.debug "Rails final dependency load path: #{self.rails_final_dependency_load_path}"
  end

  # Once the Rails Initializer has finished, the engines plugin takes over
  # and performs any post-processing tasks it may have, including:
  #
  # * loading any remaining plugins if config.plugins ended with a '*'
  # * ... nothing else right now.
  #
  def self.after_initialize
    load_remaining_plugins
  end
  
  # Loads all plugins using the Rails::Initializer extensions
  def self.load_remaining_plugins
    if rails_config.plugins.last == "*"
      puts "loading remaining plugins from #{rails_config.plugin_paths.inspect}"
      self.load_all_plugins = true
      # now call the original method. this will actually try to load ALL plugins
      # again, but any that have already been loaded will be ignored.
      rails_initializer.load_plugins 
    end
  end
  
  def self.initialize_base_public_directory
    if !File.exists?(self.public_dir)
      # create the public/engines directory, with a warning message in it.
      #log.debug "Creating public engine files directory '#{@public_dir}'"
      FileUtils.mkdir(@public_dir)
      message = File.join(File.dirname(__FILE__), '../misc/public_dir_message.txt')
      target = File.join(public_dir, "README")
      FileUtils.cp(message, target) unless File.exist?(target)
    end
  end  
end  