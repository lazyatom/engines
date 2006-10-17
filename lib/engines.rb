require 'engines/manager'
require 'engines/rails_version_detection'
require 'engines/dummy_logging'

module ::Engines
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

  # The engine manager, for marshalling
  mattr_accessor :manager
  
  class << self

    include Engines::RailsVersionDetection
    include Engines::DummyLogging

    def init
      self.root              = default_engine_root
      self.public_dir        = default_public_dir
      self.schema_info_table = default_schema_info_table
      
      load_rails_version
      initialize_filesystem
      store_load_path_marker
      store_dependency_load_path_marker

      self.manager           = Manager.instance
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

    # Stores a record of the last path with Rails added to the load path
    def store_load_path_marker
      self.rails_final_load_path = $LOAD_PATH.last
      log.debug "Rails final load path: #{self.rails_final_load_path}"
    end

    def store_dependency_load_path_marker
      unless on_rails_1_0? || (on_rails_1_1? && !on_edge?)
        self.rails_final_dependency_load_path = ::Dependencies.load_paths.last
        log.debug "Rails final dependency load path: #{self.rails_final_dependency_load_path}"
      end
    end

    # Ensures that the declared engines directory exists
    def initialize_filesystem
      if !File.exist?(root)
        log.debug "Creating engines root directory: #{root}"
        FileUtils.mkdir_p(root)
      end
    end
    
    # Return the version string for this plugin
    def version
      "#{Version::Major}.#{Version::Minor}.#{Version::Release}"
    end
    
    # Returns the Engine object for the current engine, i.e. the engine
    # in which the currently executing code lies.
    def current
      current_file = caller[0]
      self.manager.all.find do |engine|
        File.expand_path(current_file).index(File.expand_path(engine.root)) == 0
      end
    end
    
    #--
    # Delegated methods
    #++
    
    def active(*args, &block)
      manager.active(*args, &block)
    end
    
    def start(*args)
      manager.start(*args)
    end
    
    def each(*args, &block)
      manager.each(*args, &block)
    end
    
    def get(*args, &block)
      manager.get(*args, &block)
    end
    alias_method :[], :get
    
  end
end  

Engines.init

# These files must be required after the Engines module has been defined.
require 'engines/extensions/dependencies'
require 'engines/extensions/action_view'
require 'engines/extensions/action_mailer'
require 'engines/extensions/migrations'
require 'engines/extensions/active_record'

# only load the testing extensions if we are in the test environment
require 'engines/extensions/testing' if %w(test).include?(RAILS_ENV)


# For the moment, re-inject this functionality
require 'engines/config'
::Module.send(:include, Engines::Config)
