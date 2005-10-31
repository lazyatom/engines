require 'fileutils'

# = Gentlemen, Start your Engines!
# 1. Install the Engines plugin into your plugins directory
# 2. Install your engine into the /vendor/engines directory (create it if it doesn't exist)
#    e.g. /vendor/engines/my_engine/<the engine files...>
# 3. Add configuration to environment.rb
#    e.g.
#       # Add your application configuration here
#       module MyEngine
#         default_constant :TopSpeed, "TurboFast"
#       end
#    
#       start_engine "my_engine"
# 4. Run your server!
#
# = Background
# Rails Engines are a way of dropping in whoel chunks of functionality into your
# existing application without affecting *any* of your existing code. The could also 
# be described as mini-applications, or vertical applcication slices - top-to-bottom
# units which provide full MVC coverage for a certain, specific application function.
#
# As an example, the AuthenticationEngine provides a full user authorisation and
# authentication subsystem, including: 
# * controllers to manage user accounts, roles and permissions; 
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
# When you call <tt>start_engine "my_engine"</tt> in <tt>environment.rb</tt> a few important 
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
# == Model Tweaks
# Alas, tweaking model objects isn't quite so easy (yet). If you need to change the behaviour
# of model objects, you'll need to copy the model file from the engine into <tt>/app/models</tt>
# and edit the methods yourself. We're working on improving this.
#
#
# = TODO
# * add rake tasks to generate databases based on engine schema.rb files
# * some kind of testing?


RAILS_ENGINE_ROOT = File.join(RAILS_ROOT, "vendor", "engines")
if !File.exist?(RAILS_ENGINE_ROOT)
  RAILS_DEFAULT_LOGGER.debug "Creating engines directory in /vendor"
  FileUtils.mkdir_p(RAILS_ENGINE_ROOT)
end
ENGINES = Dir[RAILS_ENGINE_ROOT + "/*"].select { |d| File.directory?(d) }
ENGINE_PUBLIC_DIR = "engine_files"


module ::Dependencies
  def require_or_load(file_name)
    # try and load the framework code first
    # can't use model, as there's nothing in the name to indicate that the file is a 'model' file
    # rather than a library or anything else.
    ['controller', 'helper'].each do |type| 
      if file_name.include?('_' + type)
        ENGINES.each do |framework|
          framework_file_name = File.join(framework, 'app', "#{type}s",  File.basename(file_name))
          if File.exist? framework_file_name
            load? ? load(framework_file_name) : require(framework_file_name)
          end
        end
      end
    end

    # finally, load any application-specific controller classes.
    file_name = "#{file_name}.rb" unless ! load? || file_name [-3..-1] == '.rb'
    load? ? load(file_name) : require(file_name)
  end

  class RootLoadingModule < LoadingModule
    # hack to allow adding to the load paths within the Rails Dependencies mechanism.
    # this allows Engine classes to be unloaded and loaded along with standard
    # Rails application classes.
    def add_path(path)
      @load_paths << (path.kind_of?(ConstantLoadPath) ? path : ConstantLoadPath.new(path))
    end
  end
end

module ::ActionView
  class Base
    private
      def full_template_path(template_path, extension)

        # If the template exists in the normal application directory,
        # return that path
        default_template = "#{@base_path}/#{template_path}.#{extension}"
        return default_template if File.exist?(default_template)

        # Otherwise, check in the engines to see if the template can be found there.
        ENGINES.each do |framework|
          site_specific_path = File.join(framework.to_s, 'app', 'views',  template_path.to_s + '.' + extension.to_s)
          return site_specific_path if File.exist?(site_specific_path)
        end

        # If it cannot be found anywhere, return the default path, where the
        # user *should* have put it.  
        return "#{@base_path}/#{template_path}.#{extension}" 
      end
  end


  # add methods to handle including javascripts and stylesheets
  module Helpers
    module AssetTagHelper
      # Returns a stylesheet link tag to the named stylesheet(s) for the given
      # engine. A stylesheet with the same name as the engine is included automatically.
      # If other names are supplied, those stylesheets from within the same engine
      # will be linked too.
      #
      #   engine_stylesheet "my_engine" =>
      #   <link href="/engine_files/my_engine/stylesheets/my_engine.css" media="screen" rel="Stylesheet" type="text/css" />
      #
      #   engine_stylesheet "my_engine", "another_file", "one_more" =>
      #   <link href="/engine_files/my_engine/stylesheets/my_engine.css" media="screen" rel="Stylesheet" type="text/css" />
      #   <link href="/engine_files/my_engine/stylesheets/another_file.css" media="screen" rel="Stylesheet" type="text/css" />
      #   <link href="/engine_files/my_engine/stylesheets/one_more.css" media="screen" rel="Stylesheet" type="text/css" />
      #
      # Any options supplied as a Hash as the last argument will be processed as in
      # stylesheet_link_tag.
      #
      def engine_stylesheet(engine_name, *sources)
        options = sources.last.is_a?(Hash) ? sources.pop.stringify_keys : { }
        new_sources = []

        default = "/#{ENGINE_PUBLIC_DIR}/#{engine_name}/stylesheets/#{engine_name}.css"
        if defined?(RAILS_ROOT) && File.exists?("#{RAILS_ROOT}/public#{default}")
          new_sources << default
        end
        
        sources.each { |name| 
          new_sources << "/#{ENGINE_PUBLIC_DIR}/#{engine_name}/stylesheets/#{name}.css"
        }
        new_sources << options
        stylesheet_link_tag(*new_sources)
      end

      # Returns a javascript link tag to the named stylesheet(s) for the given
      # engine. A javascript file with the same name as the engine is included automatically.
      # If other names are supplied, those javascript from within the same engine
      # will be linked too.
      #
      #   engine_javascript "my_engine" =>
      #   <script type="text/javascript" src="/engine_files/my_engine/javascripts/my_engine.js"></script>
      #
      #   engine_javascript "my_engine", "another_file", "one_more" =>
      #   <script type="text/javascript" src="/engine_files/my_engine/javascripts/my_engine.js"></script>
      #   <script type="text/javascript" src="/engine_files/my_engine/javascripts/another_file.js"></script>
      #   <script type="text/javascript" src="/engine_files/my_engine/javascripts/one_more.js"></script>
      #
      # Any options supplied as a Hash as the last argument will be processed as in
      # javascript_include_tag.
      #
      def engine_javascript(engine_name, *sources)
        options = sources.last.is_a?(Hash) ? sources.pop.stringify_keys : { }
        new_sources = []
        
        default = "/#{ENGINE_PUBLIC_DIR}/#{engine_name}/javascripts/#{engine_name}.js"
        if defined?(RAILS_ROOT) && File.exists?("#{RAILS_ROOT}/public#{default}")
          new_sources << default
        end
        
        sources.each { |name| 
          new_sources << "/#{ENGINE_PUBLIC_DIR}/#{engine_name}/javascripts/#{name}.js"
        }
        new_sources << options
        javascript_include_tag(*new_sources)        
      end
    end
  end
end


class ::Module
  # Defines a constant within a module/class ONLY if that constant does
  # not already exist.
  #
  # This can be used to implement defaults in plugins/engines/libraries, e.g.
  # if a plugin module exists:
  #   module MyPlugin
  #     default_constant :MyDefault, "the_default_value"
  #   end
  #
  # then developers can override this default by defining that constant at
  # some point *before* the module/plugin gets loaded (such as environment.rb)
  def default_constant(name, value)
    if !self.const_defined?(name.to_s)
      self.class_eval("#{name.to_s} = #{value.inspect}")
    end
  end
end

#--
# Add these methods to the top-level object class so that they are available in all
# modules, etc
#++
class ::Object
  # Initializes a Rails Engine by loading the engine's init.rb file and
  # ensuring that any engine controllers are added to the load path.
  # This will also copy any files in a directory named 'public'
  # into the public webserver directory.
  #
  # Options can include
  # * copy_files => true | false
  #
  def start_engine(engine, options={})
    engine_dir = File.join(RAILS_ENGINE_ROOT, engine)
    
    # add the code directories of this engine to the load path
    add_engine_to_load_path(engine)
    
    # load the engine's init.rb file
    eval(IO.read(File.join(engine_dir, "init.rb")))
    
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
    app_dirs = Dir[File.join(RAILS_ENGINE_ROOT, engine) + "/app/**/*"]
    lib_dirs = Dir[File.join(RAILS_ENGINE_ROOT, engine) + "/lib/**/*"] +
               [File.join(RAILS_ENGINE_ROOT, engine, "lib")]
    load_paths = (app_dirs + lib_dirs).select { |d| 
      File.directory?(d)
    }

    RAILS_DEFAULT_LOGGER.debug "adding to load paths: #{load_paths.inspect}"

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
    public_engine_dir = File.expand_path(File.join(RAILS_ROOT, "public", ENGINE_PUBLIC_DIR))
    
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
    
    source = File.join(RAILS_ENGINE_ROOT, engine, "public")
    
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
        relative_dir = dir.gsub(File.join(RAILS_ENGINE_ROOT, engine, "public"), engine)
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
        target = file.gsub(File.join(RAILS_ENGINE_ROOT, engine, "public"), File.join(public_engine_dir, engine))
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