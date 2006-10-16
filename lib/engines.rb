require 'engines/extensions/ruby_core'

require 'engines/logging'
require 'engines/rails_versions'
require 'engines/public_files'
# ... further files are required at the bottom of this file


# Holds the Rails Engine loading logic and default constants
module Engines

  # An array of active engines. This should be accessed via the Engines.active method.
  ActiveEngines = []
  
  # The root directory for engines
  config :root, File.join(RAILS_ROOT, "vendor", "plugins")
  
  # The name of the public folder under which engine files are copied
  config :public_dir, "engine_files"
  


  class << self


    attr_accessor :rails_final_load_path
    
    # For holding the rails configuration object
    attr_accessor :rails_config
    
    # A flag to stop searching for views in the application
    attr_accessor :disable_app_views_loading
    
    # A flag to stop code being mixed in from the application
    attr_accessor :disable_app_code_mixing
    
    
    # Return the version string for this plugin
    def version
      "#{Version::Major}.#{Version::Minor}.#{Version::Release}"
    end
  
    # Initialize the engines system
    def initialize_subsystem(config)
      # Keep a hold of the Rails Configuration object
      self.rails_config = config
      detect_rails_version
      initialize_filesystem
      store_load_path_marker
    end

    # Ensures that the declared engines directory exists
    def initialize_filesystem
      if !File.exist?(Engines.config(:root))
        Engines.log.debug "Creating engines root directory: #{Engines.config(:root)}"
        FileUtils.mkdir_p(Engines.config(:root))
      end
    end

    # Stores a record of the last path with Rails added to the load path
    def store_load_path_marker
      self.rails_final_load_path = Dependencies.load_paths.last
      log.debug "Rails final load path: #{self.rails_final_load_path}"
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
        start_all(options)
      else
        args.each { |engine_name| start_engine(engine_name, options) }
      end
    end

    # Starts all available engines. Plugins are considered engines if they
    # include an init_engine.rb file, or they are named <something>_engine.
    def start_all(options={})
      plugins = Dir[File.join(config(:root), "*")]
      Engines.log.debug "considering plugins: #{plugins.inspect}"
      plugins.each { |plugin|
        start_engine(engine_name, options) if is_engine?(plugin)
      }
    end

    def start_engine(engine_name, options={})
      
      # Create a new Engine and put this engine at the front of the ActiveEngines list
      current_engine = Engine.new(engine_name)
      Engines.active.unshift current_engine
      
      Engines.log.info "Starting engine '#{current_engine.name}' from '#{File.expand_path(current_engine.root)}'"

      add_engine_to_load_path(current_engine)
      add_controllers_to_dependency_system(current_engine)
      current_engine.init(options)
    end

    # Adds all directories in the /app and /lib directories within the engine
    # to the load path
    def add_engine_to_load_path(engine)
          
      # Add ALL paths under the engine root to the load path
      load_paths  = %w(app/controllers 
                       app/helpers 
                       app/models
                       components
                       lib).collect { |dir|
                          File.join(engine.root, dir)
                        }.select { |dir| File.directory?(dir) }

      # Remove other engines from the $LOAD_PATH by matching against the engine.root values
      # in ActiveEngines. Store the removed engines in the order they came off.
      
      old_plugin_paths = []
      # assumes that all engines are at the bottom of the $LOAD_PATH
      while (File.expand_path($LOAD_PATH.last).index(File.expand_path(Engines.config(:root))) == 0) do
        old_plugin_paths.unshift($LOAD_PATH.pop)
      end


      # add these LAST on the load path.
      load_paths.reverse.each { |dir| 
        if File.directory?(dir)
          Engines.log.debug "adding #{File.expand_path(dir)} to the load path"
          $LOAD_PATH.push dir
          Dependencies.load_paths.push dir
        end
      }
      
      # Add the other engines back onto the bottom of the $LOAD_PATH. Put them back on in
      # the same order.
      $LOAD_PATH.push(*old_plugin_paths)
      $LOAD_PATH.uniq!
    end
    
    def add_controllers_to_dependency_system(current_engine)
      unless Engines.config(:edge)      
        # add the controller & component path to the Dependency system
        engine_controllers = File.join(current_engine.root, 'app', 'controllers')
        engine_components = File.join(current_engine.root, 'components')

        # This mechanism is no longer required in Rails trunk
        if Rails::VERSION::STRING =~ /^1.0/
          Controllers.add_path(engine_controllers) if File.exist?(engine_controllers)
          Controllers.add_path(engine_components) if File.exist?(engine_components)
        elsif Rails::VERSION::STRING =~ /^1.1/
          ActionController::Routing.controller_paths << engine_controllers
          ActionController::Routing.controller_paths << engine_components
        end
      end
    end
    
    # Returns the Engine object for the specified engine, e.g.:
    #    Engines.get(:login)  
    def get(name)
      active.find { |e| e.name == name.to_s || e.name == "#{name}_engine" }
    end
    alias_method :[], :get
    
    # Returns the Engine object for the current engine, i.e. the engine
    # in which the currently executing code lies.
    def current
      current_file = caller[0]
      active.find do |engine|
        File.expand_path(current_file).index(File.expand_path(engine.root)) == 0
      end
    end
    
    # Returns true if the given directory contains an engine
    def is_engine?(dir)
      File.exist?(File.join(dir, "init_engine.rb")) || # if the directory contains init_engine.rb
        (File.basename(dir) =~ /_engine$/) || # or it engines in '_engines'
        (File.basename(dir) =~ /_bundle$/)    # or even ends in '_bundle'      
    end

    # Returns an array of active engines
    def active
      ActiveEngines
    end
    
    # Pass a block to perform an operation on each engine. You may pass an argument
    # to determine the order:
    # 
    # * :load_order - in the order they were loaded (i.e. lower precidence engines first).
    # * :precidence_order - highest precidence order (i.e. last loaded) first
    def each(ordering=:precidence_order, &block)
      engines = (ordering == :load_order) ? active.reverse : active
      engines.each { |e| yield e }
    end
  end 
end

require 'engine'


# These files must be required after the Engines module has been defined.
require 'engines/extensions/dependencies'
require 'engines/extensions/action_view'
require 'engines/extensions/action_mailer'
require 'engines/extensions/migration'
require 'engines/extensions/active_record'

# only load the testing extensions if we are in the test environment
require 'engines/extensions/testing' if %w(test).include?(RAILS_ENV)
