module ::Engines
  # The name of the public directory to mirror public engine assets into
  mattr_accessor :public_dir

  # A memo of the bottom of Rails' default load path
  mattr_accessor :rails_final_load_path
  
  # A memo of the bottom of Rails Dependencies load path
  mattr_accessor :rails_final_dependency_load_path
  
  # For holding the rails configuration object
  mattr_accessor :rails_config
  
  # A reference to the current Rails::Initializer instance
  mattr_accessor :rails_initializer
  
  # A flag to stop searching for views in the application
  mattr_accessor :disable_app_views_loading
  
  # A flag to stop code being mixed in from the application
  mattr_accessor :disable_app_code_mixing

  # The table in which to store engine schema information
  mattr_accessor :schema_info_table


  mattr_accessor :original_after_initialize_block

  
  mattr_accessor :support_legacy_engines
  
  # a reference to the currently-loaded plugin. # TODO - remove this?
  mattr_accessor :current  
  
  def self.init
    self.schema_info_table = default_schema_info_table
    
    store_load_path_marker
    store_dependency_load_path_marker
    
    #initialize_base_public_directory

    self.original_after_initialize_block = self.rails_config.after_initialize_block
    self.rails_config.after_initialize {
      Engines.load_remaining_plugins
    }
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


    
  def self.load_remaining_plugins
    self.rails_initializer.load_all_remaining_plugins if self.rails_config.plugins.last == "*"
    self.original_after_initialize_block.call if self.original_after_initialize_block
  end
  
  def self.initialize_base_public_directory
    if !File.exists?(@public_dir)
      # create the public/engines directory, with a warning message in it.
      log.debug "Creating public engine files directory '#{@public_dir}'"
      FileUtils.mkdir(@public_dir)
      message_file_name = File.join(File.dirname(__FILE__), '..', 'misc', 'public_dir_message.txt')
      dest_message_file_name = File.join(public_dir, "README")
      FileUtils.cp(message_file_name, dest_message_file_name) unless File.exist?(target_message_file)
    end
  end  
end  