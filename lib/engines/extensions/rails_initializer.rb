require 'engines/plugin_list'

module ::Rails
  class Initializer
    
    # Loads a plugin, performing the extra load path/public file magic of
    # engines.
    def load_plugin_with_engine_additions(directory)
      name = plugin_name(directory)
      return false if loaded_plugins.include?(name)
      
      puts "loading plugin from #{directory} with engine additions"
      
      # add the Plugin object
      plugin = Plugin.new(plugin_name(directory), directory)
      Rails.plugins << plugin
            
      # do the other stuff that load_plugin used to do. This includes
      # allowing the plugin's init.rb to set configuration options on
      # it's instance, which can then be used in it's initialization
      load_plugin_without_engine_additions(directory)
      
      if Engines.legacy_support?
        # access to the current plugin/engine object
        Engines.current = plugin

        # load a legacy init_engine.rb file, if it exists
        init_engine_path = File.join(directory, 'init_engine.rb')
        has_init_engine = File.file?(init_engine_path)
      
        # Evaluate init_engine.rb.
        silence_warnings { eval(IO.read(init_engine_path), binding, init_engine_path) } if has_init_engine
      end

      # perform additional loading tasks
      plugin.load
            
      true
    end 
    alias_method_chain :load_plugin, :engine_additions

    
    # Allow the engines plugin to do whatever it needs to do after Rails has
    # loaded, and then call the actual after_initialize block.
    def after_initialize_with_engine_additions
      Engines.after_initialize
      after_initialize_without_engine_additions
    end
    alias_method_chain :after_initialize, :engine_additions
    
    protected
    
      def plugin_enabled_with_engine_additions?(path)
        Engines.load_all_plugins? || plugin_enabled_without_engine_additions?(path)
      end
      alias_method_chain :plugin_enabled?, :engine_additions
    
      if Engines.legacy_support?
        # lets treat legacy-style engines as plugins too. Init_engine.rb == init.rb
        def plugin_path_with_legacy_engine_support?(path)
          puts "calling engines plugin_path #{path} for plugin..."
          (File.directory?(path) && 
           File.file?(File.join(path, 'init_engine.rb'))) || 
          plugin_path_without_legacy_engine_support?(path)
        end
        alias_method_chain :plugin_path?, :legacy_engine_support
      end
      
      def plugin_name(path)
        File.basename(path)
      end
      
      def plugin_loaded?(path)
        loaded_plugins.include?(plugin_name(path))
      end     
  end
end
    


=begin    
# Return a list of plugin paths within base_path.  A plugin path is
# a directory that contains either a lib directory or an init.rb file.
# This recurses into directories which are not plugin paths, so you
# may organize your plugins within the plugin path.
def find_plugins(*base_paths)
  base_paths.flatten.inject([]) do |plugins, base_path|
    Dir.glob(File.join(base_path, '*')).each do |path|
      if plugin_path?(path)
        plugins << path if plugin_enabled?(path)
      elsif File.directory?(path)
        plugins += find_plugins(path)
      end
    end
    plugins
  end
end

def plugin_path?(path)
  File.directory?(path) and (File.directory?(File.join(path, 'lib')) or File.file?(File.join(path, 'init.rb')))
end

def plugin_enabled?(path)
  configuration.plugins.empty? || configuration.plugins.include?(File.basename(path))
end

# Load the plugin at <tt>path</tt> unless already loaded.
#
# Each plugin is initialized:
# * add its +lib+ directory, if present, to the beginning of the load path
# * evaluate <tt>init.rb</tt> if present
#
# Returns <tt>true</tt> if the plugin is successfully loaded or
# <tt>false</tt> if it is already loaded (similar to Kernel#require).
# Raises <tt>LoadError</tt> if the plugin is not found.
def load_plugin(directory)
  name = File.basename(directory)
  return false if loaded_plugins.include?(name)

  # Catch nonexistent and empty plugins.
  raise LoadError, "No such plugin: #{directory}" unless plugin_path?(directory)

  lib_path  = File.join(directory, 'lib')
  init_path = File.join(directory, 'init.rb')
  has_lib   = File.directory?(lib_path)
  has_init  = File.file?(init_path)

  # Add lib to load path *after* the application lib, to allow
  # application libraries to override plugin libraries.
  if has_lib
    application_lib_index = $LOAD_PATH.index(File.join(RAILS_ROOT, "lib")) || 0
    $LOAD_PATH.insert(application_lib_index + 1, lib_path)
  end

  # Allow plugins to reference the current configuration object
  config = configuration

  # Add to set of loaded plugins before 'name' collapsed in eval.
  loaded_plugins << name

  # Evaluate init.rb.
  silence_warnings { eval(IO.read(init_path), binding, init_path) } if has_init

  true
end
=end