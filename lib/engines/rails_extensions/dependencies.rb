module Engines::RailsExtensions::Dependencies
  def self.included(base)
    base.class_eval { alias_method_chain :require_or_load, :engine_additions }
  end
  
  def require_or_load_with_engine_additions(file_name, const_path=nil)
    return require_or_load_without_engine_additions(file_name, const_path) if Engines.disable_code_mixing

    file_loaded = false

    # try and load the plugin code first
    # can't use model, as there's nothing in the name to indicate that the file is a 'model' file
    # rather than a library or anything else.
    ['controller', 'helper'].each do |file_type| 
      # if we recognise this type
      # (this regexp splits out the module/filename from any instances of app/#{type}, so that
      #  modules are still respected.)
      if file_name =~ /^(.*app\/#{file_type}s\/)?(.*_#{file_type})(\.rb)?$/
        base_name = $2
        # ... go through the plugins from first started to last, so that
        # code with a high precidence (started later) will override lower precidence
        # implementations
        Rails.plugins.each do |plugin|
          plugin_file_name = File.expand_path(File.join(plugin.root, 'app', "#{file_type}s", base_name))
          logger.debug("checking plugin '#{plugin.name}' for '#{base_name}'")
          if File.file?("#{plugin_file_name}.rb")
            logger.debug("==> loading from plugin '#{plugin.name}'")
            file_loaded = true if require_or_load_without_engine_additions(plugin_file_name, const_path)
          end
        end
        
        # finally, load any application-specific controller classes using the 'proper'
        # rails load mechanism, EXCEPT when we're testing engines and could load this file
        # from an engine
        if Engines.disable_application_code_loading
          logger.debug("loading from application disabled.")
        else
          # Ensure we are only loading from the /app directory at this point
          app_file_name = File.join(RAILS_ROOT, 'app', "#{file_type}s", "#{base_name}")
          if File.file?("#{app_file_name}.rb")
            logger.debug("loading from application: #{base_name}")
            file_loaded = true if require_or_load_without_engine_additions(app_file_name, const_path)
          else
            logger.debug("(file not found in application)")
          end
        end        
      end 
    end
    
    # if we managed to load a file, return true. If not, default to the original method.
    # Note that this relies on the RHS of a boolean || not to be evaluated if the LHS is true.
    file_loaded || require_or_load_without_engine_additions(file_name, const_path)
  end
end

::Dependencies.send(:include, Engines::RailsExtensions::Dependencies)