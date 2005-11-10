#--
# Copyright (c) 2005 James Adam
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'ruby_extensions'
require 'dependencies_extensions'
require 'action_view_extensions'
require 'action_mailer_extensions'



# Holds the Rails Engine loading logic and default constants
module ::Engines
  
  # An array of active engines (actually paths to active engines)
  ActiveEngines = []
  
  # The root directory for engines
  config :root, File.join(RAILS_ROOT, "vendor", "plugins")
  
  # The name of the public folder under which engine files are copied
  config :public_dir, "engine_files"
  
  class << self
  
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
    # * :engine_name => the name within the plugins directory this engine resides, if
    #   different from the first parameter
    #
    # Note that if a list of engines is given, the options will apply to ALL engines.
    def start(*args)
      
      options = (args.last.is_a? Hash) ? args.pop : {}
      
      if args.empty?
        start_all
        return
      else
        args.each do |engine_name|
          start_engine(engine_name, options)
        end
      end
    end

    # Starts all available engines. Plugins are considered engines if they
    # include an init_engine.rb file, or they are named <something>_engine.
    def start_all()
      plugins = Dir[File.join(config(:root), "*")]
      RAILS_DEFAULT_LOGGER.debug "considering plugins: #{plugins.inspect}"
      plugins.each { |plugin|
        engine_name = File.basename(plugin)
        if File.exist?(File.join(plugin, "init_engine.rb")) or
           (engine_name =~ /_engine$/)
          # start the engine...
          start(engine_name)
        end
      }
    end

    def start_engine(engine_name, options={})

      current_engine = Engine.new
      current_engine.name = options[:engine_name] || engine_name
      current_engine.root = get_engine_dir(engine_name)
      
      #engine_name = options[:engine_name] || engine
      #engine_dir = get_engine_dir(engine_name)

      RAILS_DEFAULT_LOGGER.debug "Trying to start engine '#{current_engine.name}' from '#{File.expand_path(current_engine.root)}'"

      # put this engine at the front of the ActiveEngines list
      Engines::ActiveEngines.unshift current_engine #engine_dir

      # add the code directories of this engine to the load path
      add_engine_to_load_path(current_engine) #engine_dir)

      # load the engine's init.rb file
      startup_file = File.join(current_engine.root, "init_engine.rb")
      if File.exist?(startup_file)
        eval(IO.read(startup_file), binding, startup_file)
        #require startup_file
      else
        RAILS_DEFAULT_LOGGER.warn "WARNING: No init_engines.rb file found for engine '#{current_engine.name}'..."
      end

      # add the controller path to the Dependency system
      Controllers.add_path(File.join(current_engine.root, 'app', 'controllers'))

      # copy the files unless indicated otherwise
      if options[:copy_files] != false
        copy_engine_files(current_engine)
      end
    end

    # Adds all directories in the /app and /lib directories within the engine
    # to the load path
    def add_engine_to_load_path(engine)
      # Add ALL paths under the engine root to the load path
      app_dirs = [engine.root + "/app/controllers", engine.root + "/app/models",
                  engine.root + "/app/helpers"]
      lib_dirs = Dir[engine.root + "/lib/**/*"] + [engine.root, "lib"]
      load_paths = (app_dirs + lib_dirs).select { |d| 
        File.directory?(d)
      }

      # Remove other engines from the $LOAD_PATH bby matching against the engine.root values
      # in ActiveEngines. Store the removed engines in the order they came off.
      #
      # This is a hack - if Ticket http://dev.rubyonrails.com/ticket/2817 is accepted, then 
      # a new Engines system can be developed which only modifies load paths in one sweep,
      # thus avoiding this.
      #
      
      old_plugin_paths = []
      # assumes that all engines are at the bottom of the $LOAD_PATH
      while (File.expand_path($LOAD_PATH.last).index(File.expand_path(Engines.config(:root))) == 0) do
        puts "unshifting: " + $LOAD_PATH.last
        old_plugin_paths.unshift($LOAD_PATH.pop)
      end


      # add these LAST on the load path.
      load_paths.reverse.each { |dir| 
        if File.directory?(dir)
          RAILS_DEFAULT_LOGGER.debug "adding #{File.expand_path(dir)} to the load path"
          $LOAD_PATH.push(File.expand_path(dir))  
        end
      }
      
      # Add the other engines back onto the bottom of the $LOAD_PATH. Put them back on in
      # the same order.
      $LOAD_PATH.push(*old_plugin_paths)
      $LOAD_PATH.uniq!
    end

    # Replicates the subdirectories under the engine's /public directory into
    # the corresponding public directory.
    def copy_engine_files(engine)
      
     #engine_dir = get_engine_dir(engine)

      # create the /public/frameworks directory if it doesn't exist
      public_engine_dir = File.expand_path(File.join(RAILS_ROOT, "public", Engines.config(:public_dir)))
    
      if !File.exists?(public_engine_dir)
        # create the public/engines directory, with a warning message in it.
        RAILS_DEFAULT_LOGGER.debug "Creating public engine files directory '#{public_engine_dir}'"
        FileUtils.mkdir(public_engine_dir)
        File.open(File.join(public_engine_dir, "README"), "w") do |f|
          f.puts <<EOS
Files in this directory are automatically generated from your Rails Engines.
They are copied from the 'public' directories of each engine into this directory
each time Rails starts (server, console... any time 'start_engine' is called).
Any edits you make will NOT persist across the next server restart; instead you
should edit the files within the <engine_name>/public directory itself.
EOS
        end
      end
    
      source = File.join(engine.root, "public") #engine_dir, "public")
      RAILS_DEFAULT_LOGGER.debug "Attempting to copy public engine files from '#{source}'"
    
      # if there is no public directory, just return after this file
      return if !File.exist?(source)

      source_files = Dir[source + "/**/*"]
      source_dirs = source_files.select { |d| File.directory?(d) }
      source_files -= source_dirs  
      
      RAILS_DEFAULT_LOGGER.debug "source dirs: #{source_dirs.inspect}"

      # ensure that we are copying to <something>_engine, whatever the user gives us
      full_engine_name = engine.name
      full_engine_name += "_engine" if !(full_engine_name =~ /\_engine$/)


      # create all the directories, transforming the old path into the new path
      source_dirs.uniq.each { |dir|
        begin        

          # strip out the base path and add the result to the public path
          relative_dir = dir.gsub(File.join(engine.root, "public"), full_engine_name)
          target_dir = File.join(public_engine_dir, relative_dir)
          unless File.exist?(target_dir)
            RAILS_DEFAULT_LOGGER.debug "creating directory '#{target_dir}'"
            FileUtils.mkdir_p(File.join(public_engine_dir, relative_dir))
          end
        rescue Exception => e
          raise "Could not create directory #{target_dir}: \n" + e
        end
      }



      # copy all the files, transforming the old path into the new path
      source_files.uniq.each { |file|
        begin
          # change the path from the ENGINE ROOT to the public directory root for this engine
          target = file.gsub(File.join(engine.root, "public"), 
                             File.join(public_engine_dir, full_engine_name))
          unless File.exist?(target) && FileUtils.identical?(file, target)
            RAILS_DEFAULT_LOGGER.debug "copying file '#{file}' to '#{target}'"
            FileUtils.cp(file, target)
          end 
        rescue Exception => e
          raise "Could not copy #{file} to #{target}: \n" + e 
        end
      }
    end

  
    #private
      # Return the directory in which this engine is present
      def get_engine_dir(engine_name)
        engine_dir=File.join(Engines.config(:root), engine_name.to_s)

        if !File.exist?(engine_dir)
          # try adding "_engine" to the end of the path.
          engine_dir += "_engine"
          if !File.exist?(engine_dir)
            raise "Cannot find the engine '#{engine_name}' in either /vendor/plugins/#{engine} or /vendor/plugins/#{engine}_engine..."
          end
        end      
      
        engine_dir
      end
    
    # Returns the Engine object for the specified engine, e.g.:
    #    Engines.get(:login)  
    def get(name)
      ActiveEngines.find { |e| e.name == name.to_s || e.name == "#{name}_engine" }
    end
    
    # Returns the Engine object for the current engine, i.e. the engine
    # in which the currently executing code lies.
    def current()
      #puts caller.inspect
      #puts ">>> " + caller[0]
      current_file = caller[0]
      ActiveEngines.find do |engine|
        File.expand_path(current_file).index(File.expand_path(engine.root)) == 0
      end
    end    
  end 
end

# A simple class for holding information about loaded engines
class Engine
  
  # Returns the base path of this engine
  attr_accessor :root
  
  # Returns the name of this engine
  attr_reader :name
  
  def name=(val) @name = val.to_s end
  def to_s() "Engine<#{@name}>"   end
end