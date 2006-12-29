module Engines::RailsExtensions::ActionView
  def self.included(base)
    base.class_eval { alias_method_chain :full_template_path, :engine_additions }
  end

  private
    def full_template_path_with_engine_additions(template_path, extension)
      # Otherwise, check in the engines to see if the template can be found there.
      # Load this in order so that more recently started plugins will take priority.
      Rails.plugins.reverse.each do |plugin|
        plugin_specific_path = File.join(plugin.root, 'app', 'views',  
                                       template_path.to_s + '.' + extension.to_s)
        return plugin_specific_path if File.exist?(plugin_specific_path)
      end

      # If it cannot be found anywhere, return the default path, where the
      # user *should* have put it. If we've specifically disabled loading from
      # the application (for example, in tests), then return nil
      if Engines.disable_application_view_loading
        return nil
      else
        return full_template_path_without_engine_additions(template_path, extension)
      end
    end  
end

::ActionView::Base.send(:include, Engines::RailsExtensions::ActionView)