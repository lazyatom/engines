require 'fileutils'

require 'ruby_extensions'
require 'dependencies_extensions'
require 'action_view_extensions'

# = Gentlemen, Start your Engines!
# 1. Install the Engines plugin into your plugins directory
# 2. Install your engine into the /vendor/engines directory (create it if it doesn't exist)
#    e.g. /vendor/engines/my_engine/<the engine files...>
# 3. Add configuration to environment.rb
#    e.g.
#       # Add your application configuration here
#       module MyEngine
#         config :TopSpeed, "TurboFast"
#       end
#    
#       Engine.start "my_engine"
# 4. Run your server!
#
#
#
# = Background
# Rails Engines are a way of dropping in whoel chunks of functionality into your
# existing application without affecting *any* of your existing code. The could also 
# be described as mini-applications, or vertical application slices - top-to-bottom
# units which provide full MVC coverage for a certain, specific application function.
#
# As an example, the Login Engine provides a full user login subsystem, including: 
# * controllers to manage user accounts; 
# * helpers for you to interact with account information from other 
#   parts of your application; 
# * the model objects and schemas to create the required tables; 
# * stylesheets and javascript files to enhance the views; 
# * and any other library files required.
#
# Once the Rails Core team decides on a suitable method for packaging plugins, Engines
# can be distributed using the same mechanisms. If you are developing engines yourself
# for use across multiple projects, linking them as svn externals allows seamless updating
# of bugfixes across multiple applications.
#
#
#
# = Building an Engine
# In your Rails application, you should have a directory called 'engines' in the vendor
# directory (alongside plugins). This directory will contain one subdirectory for
# each engine. Here's a sample rails application with a detailed listing of an example 
# engines as a concrete example:
#
#   RAILS_ROOT
#     |- app
#     |- lib
#     |- config
#     |- <... other directories ...>
#     |- vendor
#         |-engines 
#             |- my_engine
#                   |- init.rb
#                   |- app
#                   |     |- controllers
#                   |     |- model
#                   |     |- helpers
#                   |     |- views
#                   |- db
#                   |- doc
#                   |- lib
#                   |- public
#                   |     |- javascripts
#                   |     |- stylesheets
#                   |- script
#
#
# The internal structure of an engine mirrors the familiar core of a Rails application,
# with most of the engine within the <tt>app</tt> subdirectory. Within <tt>app</tt>, the controllers,
# views and model objects behave just as you might expect if there in teh top-level <tt>app</tt>
# directory.
#
# When you call <tt>Engines.start "my_engine"</tt> in <tt>environment.rb</tt> a few important 
# bits of black magic voodoo happen:
# * the engine's controllers, views and modesl are mixed in to your running Rails application; 
# * files in the <tt>lib</tt> directory of your engine are made available to the rest of your system
# * any directory structure in the folder <tt>public</tt> within your engine is made servable
#   by the webserver
# * the file <tt>init.rb</tt> is loaded from within the engine (just like a plugin).
#
# From within <tt>init.rb</tt> you should load any libraries from your <tt>lib</tt> directory
# that your engine might need to function. You can also perform any configuration required.
#
#
# = Tweaking Engines
# One of the best things about Engines is that if you don't like the default behaviour of any
# component, you can override it without needing to overhaul the whole engine. This makes adding
# your customisations to engines almost painless, and allows for upgrading/updating engine code
# without affecting the specialisations you need for your particular application.
#
#
# == View Tweaks
# These are the simplest - just drop your customised view (or partial) into you <tt>/app/views</tt>
# directory in the corresponding location for the engine, and your view will be used in
# preference to the engine view. For example, if we have a ItemController with an action 'show',
# it will (normally) expect to find its view as <tt>report/show.rhtml</tt> in the <tt>views</tt>
# directory. The view is found in the engine at 
# <tt>/vendor/engines/my_engine/app/views/report/show.rhtml</tt>.
# However, if you create the file <tt>/app/views/report/show.rhtml</tt>, that file will be used
# instead! The same goes for partials.
#
#
# == Controller Tweaks
# You can override controller behaviour by replacing individual controller methods
# with your custom behaviour. Lets say that our ItemController's 'show' method isn't up to
# scratch, but the rest of it behaves just fine. To override the single method, create
# <tt>/app/controllers/item_controller.rb</tt>, just as if it were going to be a new
# controller in a regular Rails application. then, implement your show method as you would
# like it to happen.
#
# ... and that's it. Your custom code will be mixed in to the engine controller, replacing
# its old method with your custom code.
#
#
# == Model Tweaks
# Alas, tweaking model objects isn't quite so easy (yet). If you need to change the behaviour
# of model objects, you'll need to copy the model file from the engine into <tt>/app/models</tt>
# and edit the methods yourself. We're working on improving this.
#
#
#
# = TODO / Future Work
# * add rake tasks to generate databases based on engine schema.rb files
# * some kind of testing? Integrate with http://techno-weenie.net/svn/projects/test/
#



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
    # into the public webserver directory.
    #
    # Options can include
    # * copy_files => true | false
    #
    def start(engine, options={})
      engine_dir = File.join(Engines.config(:root), engine)
    
      RAILS_DEFAULT_LOGGER.debug "Starting engine '#{engine}' from '#{File.expand_path(engine_dir)}'"
    
      # put this engine at the front of the ActiveEngines list
      Engines::ActiveEngines.unshift engine_dir
    
      # add the code directories of this engine to the load path
      add_engine_to_load_path(engine)
    
      # load the engine's init.rb file
      eval(IO.read(File.join(engine_dir, "init_engine.rb")))
    
      # add the controller path to the Dependency system
      Controllers.add_path(File.join(engine_dir, 'app', 'controllers'))
    
      # copy the files unless indicated otherwise
      if options[:copy_files] != false
        copy_engine_files(engine)
      end
    end

    # Adds all directories in the /app and /lib directories within the engine
    # to the load path
    def add_engine_to_load_path(engine)
      # Add ALL paths under the engine root to the load path
      app_dirs = [File.join(Engines.config(:root), engine) + "/app/controllers",
                  File.join(Engines.config(:root), engine) + "/app/models",
                  File.join(Engines.config(:root), engine) + "/app/helpers"]
      lib_dirs = Dir[File.join(Engines.config(:root), engine) + "/lib/**/*"] +
                 [File.join(Engines.config(:root), engine, "lib")]
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
    
      source = File.join(Engines.config(:root), engine, "public")
    
      # if there is no public directory, just return after this file
      return if !File.exist?(source)   
      #destination = File.expand_path(File.join(public_engine_dir, engine))

      source_files = Dir[source + "/**/*"]
      source_dirs = source_files.select { |d| File.directory?(d) }
      source_files -= source_dirs

      # create all the directories, transforming the old path into the new path
      source_dirs.uniq.each { |dir|
        begin        
          # strip out the base path and add the result to the public path
          relative_dir = dir.gsub(File.join(Engines.config(:root), engine, "public"), engine)
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
          target = file.gsub(File.join(Engines.config(:root), engine, "public"), 
                             File.join(public_engine_dir, engine))
          unless File.exist?(target) && FileUtils.identical?(file, target)
            RAILS_DEFAULT_LOGGER.debug "copying file '#{file}' to '#{target}'"
            FileUtils.cp(file, target)
          end 
        rescue Exception => e
          raise "Could not copy #{file} to #{target}: \n" + e 
        end
      }
    end
  
  end
end



#--
# Create the Engines directory if it isn't present
#++
if !File.exist?(Engines.config(:root))
  RAILS_DEFAULT_LOGGER.debug "Creating engines directory in /vendor"
  FileUtils.mkdir_p(Engines.config(:root))
end