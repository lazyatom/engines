require 'engines/logging'
require 'engines/rails_versions'
require 'engines/public_files'
# ... further files are required at the bottom of this file, once
# the basic Engines config has been established.


# Holds the Rails Engine loading logic and default constants
module Engines

  # An array of active engines, the first having most precidence
  mattr_accessor :active

  # The directory from which to load engines
  mattr_accessor :root
  
  # The name of the public directory to mirror public engine assets into
  mattr_accessor :public_dir

  # A memo of the bottom of Rails' default load path
  mattr_accessor :rails_final_load_path
  
  # A memo of the bottom of Rails Dependencies load path
  mattr_accessor :rails_final_dependency_load_path
  
  # For holding the rails configuration object
  mattr_accessor :rails_config
  
  # A flag to stop searching for views in the application
  mattr_accessor :disable_app_views_loading
  
  # A flag to stop code being mixed in from the application
  mattr_accessor :disable_app_code_mixing

  # The table in which to store engine schema information
  mattr_accessor :schema_info_table
  

  def self.default_engine_root
    File.join(RAILS_ROOT, "vendor", "plugins")
  end

  def self.default_public_dir
    File.join(RAILS_ROOT, "public", "engine_files")
  end
  
  def self.default_schema_info_table
    "engine_schema_info"
  end


  # Initialize the engines system
  def self.initialize_subsystem
    self.active            = []
    self.root              = default_engine_root
    self.public_dir        = default_public_dir
    self.schema_info_table = default_schema_info_table

    load_rails_version
    initialize_filesystem
    store_load_path_marker
    store_dependency_load_path_marker
  end

  # Ensures that the declared engines directory exists
  def self.initialize_filesystem
    if !File.exist?(self.root)
      Engines.log.debug "Creating engines root directory: #{self.root}"
      FileUtils.mkdir_p(self.root)
    end
  end

  # Stores a record of the last path with Rails added to the load path
  def self.store_load_path_marker
    self.rails_final_load_path = $LOAD_PATH.last
    log.debug "Rails final load path: #{self.rails_final_load_path}"
  end

  def self.store_dependency_load_path_marker
    unless Engines.on_rails_1_0? || (Engines.on_rails_1_1? && !Engines.on_edge?)
      self.rails_final_dependency_load_path = Dependencies.load_paths.last
      log.debug "Rails final dependency load path: #{self.rails_final_load_path}"
    end
  end


  #--------------------------------------------------------------------------
  # Starting Engines
  #++------------------------------------------------------------------------

  # Initializes a Rails Engine by loading the engine's init.rb file and
  # ensuring that any engine controllers are added to the load path.
  # This will also copy any files in a directory named 'public'
  # into the public webserver directory. Example usage:
  #
  #   Engines.start :login
  #   Engines.start :login_engine  # equivalent
  #
  # A list of engine names can be specified:
  #
  #   Engines.start :login, :user, :wiki
  #
  # The engines will be loaded in the order given.
  # If no engine names are given, all engines will be started.
  #
  # Options can include:
  # * :copy_files => true | false
  #
  # Note that if a list of engines is given, the options will apply to ALL engines.
  def self.start(*args)
    options = (args.last.is_a? Hash) ? args.pop : {}
    if args.empty? # ignoring the options Hash
      start_all(options)
    else
      args.each { |engine_name| start_engine(engine_name, options) }
    end
  end

  # Starts all available engines. Plugins are considered engines if they
  # include an init_engine.rb file, or they are named <something>_engine.
  def self.start_all(options={})
    plugins = Dir[File.join(self.root, "*")]
    Engines.log.debug "considering plugins: #{plugins.inspect}"
    plugins.each { |plugin|
      start_engine(engine_name, options) if is_engine?(plugin)
    }
  end

  def self.start_engine(engine_name, options={})
    current_engine = Engine.new(engine_name)
    Engines.active.unshift current_engine
    Engines.log.info "Starting engine '#{current_engine.name}' from '#{File.expand_path(current_engine.root)}'"
    current_engine.start(options)
  end

  # Return the version string for this plugin
  def self.version
    "#{Version::Major}.#{Version::Minor}.#{Version::Release}"
  end
  
  # Returns the Engine object for the specified engine, e.g.:
  #    Engines.get(:login)  
  def self.get(name)
    active.find { |e| e.name == name.to_s || e.name == "#{name}_engine" }
  end
  
  class << self
    alias_method :[], :get
  end
  
  # Returns the Engine object for the current engine, i.e. the engine
  # in which the currently executing code lies.
  def self.current
    current_file = caller[0]
    active.find do |engine|
      File.expand_path(current_file).index(File.expand_path(engine.root)) == 0
    end
  end
  
  # Returns true if the given directory contains an engine
  def self.is_engine?(dir)
    File.exist?(File.join(dir, "init_engine.rb")) || # if the directory contains init_engine.rb
      (File.basename(dir) =~ /_engine$/) || # or it engines in '_engines'
      (File.basename(dir) =~ /_bundle$/)    # or even ends in '_bundle'      
  end
  
  # Pass a block to perform an operation on each engine. You may pass an argument
  # to determine the order:
  # 
  # * :load_order - in the order they were loaded (i.e. lower precidence engines first).
  # * :precidence_order - highest precidence order (i.e. last loaded) first
  def self.each(ordering=:precidence_order, &block)
    engines = (ordering == :load_order) ? active.reverse : active
    engines.each { |e| yield e }
  end 
end

require 'engine'

# Initialize engines subsystem - detect versions, etc, before loading
# the rest of the engines extensions
::Engines.initialize_subsystem


# These files must be required after the Engines module has been defined.
require 'engines/extensions/dependencies'
require 'engines/extensions/action_view'
require 'engines/extensions/action_mailer'
require 'engines/extensions/migrations'
require 'engines/extensions/active_record'

require 'engines/config'

# For the moment, re-inject this functionality
::Module.send(:include, Engines::Config)

# only load the testing extensions if we are in the test environment
require 'engines/extensions/testing' if %w(test).include?(RAILS_ENV)
