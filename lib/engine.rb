# A simple class for holding information about loaded engines
class Engine
  
  # Returns the base path of this engine
  attr_accessor :root
  
  # Returns the name of this engine
  attr_reader :name
  
  # An attribute for holding the current version of this engine. There are three
  # ways of providing an engine version. The simplest is using a string:
  #
  #   Engines.current.version = "1.0.7"
  #
  # Alternatively you can set it to a module which contains Major, Minor and Release
  # constants:
  #
  #   module LoginEngine::Version
  #     Major = 1; Minor = 0; Release = 6;
  #   end
  #   Engines.current.version = LoginEngine::Version
  #
  # Finally, you can set it to your own Proc, if you need something really fancy:
  #
  #   Engines.current.version = Proc.new { File.open('VERSION', 'r').readlines[0] }
  # 
  attr_writer :version
  
  # Engine developers can store any information they like in here.
  attr_accessor :info
  
  # Creates a new object holding information about an Engine.
  def initialize(name)
    @root = ''
    suffixes = ['', '_engine', '_bundle']
    while !File.exist?(@root) && !suffixes.empty?
      suffix = suffixes.shift
      @root = File.join(Engines.root, name.to_s + suffix)
    end

    if !File.exist?(@root)
      raise "Cannot find the engine '#{name}' in either /vendor/plugins/#{name}, " +
        "/vendor/plugins/#{name}_engine or /vendor/plugins/#{name}_bundle."
    end      
    
    @name = File.basename(@root)
    @info = '(none)'
  end
    
  # Returns the version string of this engine
  def version
    case @version
    when Module
      "#{@version::Major}.#{@version::Minor}.#{@version::Release}"
    when Proc         # not sure about this
      @version.call
    when NilClass
      'unknown'
    else
      @version
    end
  end
  
  # A shortcut to the Engines logger
  def log
    Engines.log
  end
  
  # Activates this engine
  def start(options={})
    # copy the files unless indicated otherwise
    mirror_engine_files unless options[:copy_files] == false

    inject_into_load_path
    inject_into_routing
    
    run_startup_file
  end
  

  # Adds all directories in the /app and /lib directories within the engine
  # to the load path
  def inject_into_load_path
        
    # Add ALL paths under the engine root to the load path
    %w(app/controllers 
       app/helpers 
       app/models
       components
       lib).collect { |dir|
          File.join(self.root, dir)
        }.select { |dir| File.directory?(dir) }.each do |path|
      insert_into_load_path(path)   
    end
  end
  
  def inject_into_routing
    # add the controller & component path to the Dependency system
    engine_controllers = File.join(self.root, 'app', 'controllers')
    engine_components = File.join(self.root, 'components')

    # This mechanism is no longer required in Rails trunk
    if Engines.on_rails_1_0?
      Controllers.add_path(engine_controllers) if File.exist?(engine_controllers)
      Controllers.add_path(engine_components) if File.exist?(engine_components)
    else
      ActionController::Routing.controller_paths << engine_controllers
      ActionController::Routing.controller_paths << engine_components
    end
  end

  def run_startup_file
    # load the engine's init.rb file
    startup_file = File.join(self.root, "init_engine.rb")
    if File.exist?(startup_file)
      eval(IO.read(startup_file), binding, startup_file)
    else
      log.debug "No init_engines.rb file found for engine '#{self.name}'..."
    end    
  end

  
  # Returns a string representation of this engine
  def to_s
    "Engine<'#{@name}' [#{version}]:#{root.gsub(RAILS_ROOT, '')}>"
  end
  
  # Replicates the subdirectories under the engine's /public directory into
  # the corresponding public directory.
  def mirror_engine_files
    
    begin
      Engines.initialize_base_public_directory
  
      log.debug "Attempting to copy public engine files from '#{source_public_dir}'"
  
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
          target = file.gsub(File.join(root, "public"), 
                             self.public_dir)
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
  
  def asset_base_uri
    "/#{File.basename(Engines.public_dir)}/#{name}"
  end
  
  private 
  
    # return the path to this Engine's public files (with a leading '/' for use in URIs)
    def destination_public_dir
      File.join(Engines.public_dir, name)
    end
  
    def source_public_dir
      File.join(self.root, "public")
    end
 
    def insert_into_load_path(path)
      load_path_index = $LOAD_PATH.index(Engines.rails_final_load_path)
      $LOAD_PATH.insert(load_path_index + 1, path)

      if Engines.on_rails_1_2? or Engines.on_edge?
        dependency_load_path_index = Dependencies.load_paths.index(Engines.rails_final_dependency_load_path)
        Dependencies.load_paths.insert(dependency_load_path_index + 1, path)
      end
    end 
end