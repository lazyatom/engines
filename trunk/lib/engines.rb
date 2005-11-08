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
        args.each do |engine|
      
          engine_name = options[:engine_name] || engine
          engine_dir = get_engine_dir(engine_name)
    
          RAILS_DEFAULT_LOGGER.debug "Trying to start engine '#{engine}' from '#{File.expand_path(engine_dir)}'"
    
          # put this engine at the front of the ActiveEngines list
          Engines::ActiveEngines.unshift engine_dir
    
          # add the code directories of this engine to the load path
          add_engine_to_load_path(engine_dir)
    
          # load the engine's init.rb file
          startup_file = File.join(engine_dir, "init_engine.rb")
          if File.exist?(startup_file)
            eval(IO.read(startup_file))
          else
            RAILS_DEFAULT_LOGGER.warn "WARNING: No init_engines.rb file found for engine '#{engine}'..."
          end
    
          # add the controller path to the Dependency system
          Controllers.add_path(File.join(engine_dir, 'app', 'controllers'))
    
          # copy the files unless indicated otherwise
          if options[:copy_files] != false
            copy_engine_files(engine)
          end
        end
      end
    end

    # Starts all available engines. Plugins are considered engines if they
    # include an init_engine.rb file, or they are named <something>_engine.
    def start_all
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

    # Adds all directories in the /app and /lib directories within the engine
    # to the load path
    def add_engine_to_load_path(engine_dir)
      # Add ALL paths under the engine root to the load path
      app_dirs = [engine_dir + "/app/controllers", engine_dir + "/app/models",
                  engine_dir + "/app/helpers"]
      lib_dirs = Dir[engine_dir + "/lib/**/*"] + [engine_dir, "lib"]
      load_paths = (app_dirs + lib_dirs).select { |d| 
        File.directory?(d)
      }

      # add these LAST on the load path.
      load_paths.reverse.each { |dir| 
        if File.directory?(dir)
          RAILS_DEFAULT_LOGGER.debug "adding #{File.expand_path(dir)} to the load path"
          $:.push(File.expand_path(dir))  
        end
      }     
    end

    # Replicates the subdirectories under the engine's /public directory into
    # the corresponding public directory.
    def copy_engine_files(engine)
      
     engine_dir = get_engine_dir(engine)

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
    
      source = File.join(engine_dir, "public")
      RAILS_DEFAULT_LOGGER.debug "Attempting to copy public engine files from '#{source}'"
    
      # if there is no public directory, just return after this file
      return if !File.exist?(source)

      source_files = Dir[source + "/**/*"]
      source_dirs = source_files.select { |d| File.directory?(d) }
      source_files -= source_dirs  
      
      RAILS_DEFAULT_LOGGER.debug "source dirs: #{source_dirs.inspect}"

      # ensure that we are copying to <something>_engine, whatever the user gives us
      full_engine_name = engine.to_s
      full_engine_name += "_engine" if !(full_engine_name =~ /\_engine$/)


      # create all the directories, transforming the old path into the new path
      source_dirs.uniq.each { |dir|
        begin        

          # strip out the base path and add the result to the public path
          relative_dir = dir.gsub(File.join(engine_dir, "public"), full_engine_name)
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
          target = file.gsub(File.join(engine_dir, "public"), 
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
      def get_engine_dir(engine)
        engine_dir=File.join(Engines.config(:root), engine.to_s)

        if !File.exist?(engine_dir)
          # try adding "_engine" to the end of the path.
          engine_dir += "_engine"
          if !File.exist?(engine_dir)
            raise "Cannot find the engine '#{engine}' in either /vendor/plugins/#{engine} or /vendor/plugins/#{engine}_engine..."
          end
        end      
      
        engine_dir
      end  
  end 
end