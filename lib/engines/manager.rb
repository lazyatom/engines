require 'singleton'

module ::Engines
  class Manager
    include Singleton
  
    attr_reader :all
  
    attr_reader :active
  
    def initialize
      @all = []
      @active = []
    
      find_all_engines 
    end

    # Returns the Engine object for the specified engine, e.g.:
    #    EngineManager.get(:login)  
    def get(name)
      @all.find { |e| e.name == name.to_s || e.name == "#{name}_engine" }
    end
    alias_method :[], :get
  
    def find_all_engines
      possible_engines = Dir[File.join(Engines.root, "*")]
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

    def log(*args, &block)
      Engines.log(*args, &block)
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
          @active.unshift(engine)
        end
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
end
