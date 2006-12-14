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

      # perform additional loading tasks like mirroring public assets
      # and adding app directories to the appropriate load paths
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
          
      def plugin_name(path)
        File.basename(path)
      end
      
      def plugin_loaded?(path)
        loaded_plugins.include?(plugin_name(path))
      end     
  end
end