module Engines::RailsExtensions::ActionView
  def self.included(base)
    base.class_eval { alias_method_chain :full_template_path, :engine_additions }
  end

  private
    def full_template_path_with_engine_additions(template_path, extension)

      path_in_app_directory = full_template_path_from_application(template_path, extension)
      
      # First check for this template in the application. If it exists, the user has
      # overridden anything from the plugin, so use it (unless we're testing plugins;
      # see full_template_path_from_application())
      return path_in_app_directory if File.exist?(path_in_app_directory)
      
      # Otherwise, check in the plugins to see if the template can be found there.
      # Load this in order so that more recently started plugins will take priority.
      Rails.plugins.in_precidence_order.each do |plugin|
        plugin_specific_path = File.join(plugin.root, 'app', 'views',  
                                       template_path.to_s + '.' + extension.to_s)
        return plugin_specific_path if File.exist?(plugin_specific_path)
      end

      # If it cannot be found anywhere, return the default path.
      return path_in_app_directory
    end 
  
    # Return a path to this template within our default app/views directory.
    # In some circumstances, we may wish to prevent users from overloading views,
    # such as when we are testing plugins with views. In this case, return nil.
    def full_template_path_from_application(template_path, extension)
      if Engines.disable_application_view_loading
        return nil
      else
        return full_template_path_without_engine_additions(template_path, extension)
      end      
    end
end

::ActionView::Base.send(:include, Engines::RailsExtensions::ActionView)