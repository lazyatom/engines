require 'singleton'

require 'engines/dummy_logging'
require 'engines/rails_version_detection'
require 'engine'
# ... further files are required at the bottom of this file, once
# the basic Engines config has been established.


class EngineManager
  include Singleton
  include RailsVersionDetection
  include DummyLogging
  
  attr_reader :all
  
  attr_reader :active
  
  attr_accessor :rails_config
  
  attr_accessor :schema_info_table
  
  attr_reader :root
  
  def initialize
    @all = []
    @active = []
    @root_dir = default_engine_root_dir
    @public_dir = default_public_dir
    @schema_info_table = default_schema_info_table
    @rails_final_load_path = nil
    @rails_final_dependency_load_path = nil
    @rails_config = nil
    @load_app_views = true
    @mix_engine_code = true
    
    load_rails_version
    initialize_filesystem
    store_load_path_marker
    store_dependency_load_path_marker    
    
    find_all_engines
    
  end

  def default_engine_root
    File.join(RAILS_ROOT, "vendor", "plugins")
  end

  def default_public_dir
    File.join(RAILS_ROOT, "public", "engine_files")
  end
  
  def default_schema_info_table
    "engine_schema_info"
  end

  # Ensures that the declared engines directory exists
  def initialize_filesystem
    if !File.exist?(root)
      Engines.log.debug "Creating engines root directory: #{root}"
      FileUtils.mkdir_p(root)
    end
  end

  # Stores a record of the last path with Rails added to the load path
  def store_load_path_marker
    @rails_final_load_path = $LOAD_PATH.last
    log.debug "Rails final load path: #{@rails_final_load_path}"
  end

  def store_dependency_load_path_marker
    unless on_rails_1_0? || (on_rails_1_1? && !on_edge?)
      @rails_final_dependency_load_path = Dependencies.load_paths.last
      log.debug "Rails final dependency load path: #{@rails_final_dependency_load_path}"
    end
  end

  # Return the version string for this plugin
  def version
    "#{Version::Major}.#{Version::Minor}.#{Version::Release}"
  end
  
  # Returns the Engine object for the specified engine, e.g.:
  #    EngineManager.get(:login)  
  def get(name)
    active.find { |e| e.name == name.to_s || e.name == "#{name}_engine" }
  end
  alias_method :[], :get
  
  def find_all_engines
    possible_engines = Dir[File.join(root, "*")]
    log.debug "considering possible engines: #{possible_engines.inspect}"
    possible_engines.each do |engine_dir|
      add_engine(Engine.new(engine_dir)) if is_engine?(engine_dir)
    end    
  end
  
  # Returns true if the given directory contains an engine
  def is_engine?(dir)
    File.exist?(File.join(dir, "init_engine.rb")) || # if the directory contains init_engine.rb
      (File.basename(dir) =~ /_engine$/) || # or it engines in '_engines'
      (File.basename(dir) =~ /_bundle$/)    # or even ends in '_bundle'      
  end

  def add_engine(engine)
    @all << engine
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
  def start(*args)
    options = (args.last.is_a? Hash) ? args.pop : {}
    if args.empty? # ignoring the options Hash
      @all.each { |engine| engine.start(options) }
    else
      args.each do |engine_name| 
        engine = get(engine_name)
        raise "Cannot find engine called '#{engine_name}'. Aborting!" if engine.nil?
        engine.start(options)
      end
    end
  end

  # Returns the Engine object for the current engine, i.e. the engine
  # in which the currently executing code lies.
  def current
    current_file = caller[0]
    active.find do |engine|
      File.expand_path(current_file).index(File.expand_path(engine.root)) == 0
    end
  end
  
  # Pass a block to perform an operation on each engine. You may pass an argument
  # to determine the order:
  # 
  # * :load_order - in the order they were loaded (i.e. lower precidence engines first).
  # * :precidence_order - highest precidence order (i.e. last loaded) first
  def each(ordering=:precidence_order, &block)
    engines = (ordering == :load_order) ? @active.reverse : @active
    engines.each { |e| yield e }
  end
  
end

::Engines = EngineManager.instance


# Holds the Rails Engine loading logic and default constants
module OldEngines

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
end




# These files must be required after the Engines module has been defined.
require 'extensions/dependencies'
require 'extensions/action_view'
require 'extensions/action_mailer'
require 'extensions/migrations'
require 'extensions/active_record'

require 'config'

# For the moment, re-inject this functionality
::Module.send(:include, Engines::Config)

# only load the testing extensions if we are in the test environment
require 'extensions/testing' if %w(test).include?(RAILS_ENV)
