module Engines::RailsExtensions::Dependencies
  def self.included(base)
    base.class_eval { alias_method_chain :require_or_load, :engine_additions }
  end
  
  def require_or_load_with_engine_additions(file_name, const_path=nil)
    #Engines.log.debug("Engines 1.1 require_or_load: #{file_name}")

    return require_or_load_without_engine_additions(file_name, const_path) if Engines.disable_code_mixing

    found = false

    # try and load the plugin code first
    # can't use model, as there's nothing in the name to indicate that the file is a 'model' file
    # rather than a library or anything else.
    ['controller', 'helper'].each do |type| 
      # if we recognise this type
      # (this regexp splits out the module/filename from any instances of app/#{type}, so that
      #  modules are still respected.)
      if file_name =~ /^(.*app\/#{type}s\/)?(.*_#{type})(\.rb)?$/
 
        # ... go through the plugins from first started to last, so that
        # code with a high precidence (started later) will override lower precidence
        # implementations
        Rails.plugins.each do |plugin|
 
          plugin_file_name = File.expand_path(File.join(plugin.root, 'app', "#{type}s", $2))
          #Engines.log.debug("checking engine '#{plugin.name}' for '#{plugin_file_name}'")
          if File.exist?("#{plugin_file_name}.rb")
            #Engines.log.debug("==> loading from plugin '#{plugin.name}'")
            require_or_load_without_engine_additions(plugin_file_name, const_path)
            found = true
          end
        end
      end 
    end
    
    # finally, load any application-specific controller classes using the 'proper'
    # rails load mechanism, EXCEPT when we're testing engines and could load this file
    # from an engine
    if Engines.disable_application_code_loading && found
      false
    else
      require_or_load_without_engine_additions(file_name, const_path)
    end
  end
end

::Dependencies.send(:include, Engines::RailsExtensions::Dependencies)