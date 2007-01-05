module Engines::RailsExtensions::Templates
  
  # Override the finding of partials and views
  module ActionView
    def self.included(base)
      base.class_eval { alias_method_chain :full_template_path, :engine_additions }
    end

    private
      def full_template_path_with_engine_additions(template_path, extension)
        path_in_app_directory = full_template_path_from_application(template_path, extension)
      
        # First check for this template in the application. If it exists, the user has
        # overridden anything from the plugin, so use it (unless we're testing plugins;
        # see full_template_path_from_application())
        return path_in_app_directory if path_in_app_directory && File.exist?(path_in_app_directory)
      
        # Otherwise, check in the plugins to see if the template can be found there.
        # Load this in order so that more recently started plugins will take priority.
        Rails.plugins.by_precedence do |plugin|
          plugin_specific_path = File.join(plugin.root, 'app', 'views',  
                                         template_path.to_s + '.' + extension.to_s)
          return plugin_specific_path if File.exist?(plugin_specific_path)
        end

        # If it cannot be found anywhere, return the default path.
        return full_template_path_without_engine_additions(template_path, extension)
      end 
  
      # Return a path to this template within our default app/views directory.
      # In some circumstances, we may wish to prevent users from overloading views,
      # such as when we are testing plugins with views. In this case, return "".
      def full_template_path_from_application(template_path, extension)
        if Engines.disable_application_view_loading
          nil
        else
          full_template_path_without_engine_additions(template_path, extension)
        end    
      end
  end


  # Ensure that plugins can contain layouts
  module Layout
    def self.included(base)
      base.class_eval { alias_method_chain :layout_list, :engine_additions }
    end

    private
      def layout_list_with_engine_additions
        plugin_layouts = Rails.plugins.by_precedence.map do |p| 
          File.join(p.root,"app", "views", "layouts")
        end
        layout_list_without_engine_additions + Dir["{#{plugin_layouts.join(",")}}/**/*"]
      end
  end
  
  
  # The way ActionMailer is coded in terms of finding templates is very restrictive, to the point
  # where all templates for rendering must exist under the single base path. This is difficult to
  # work around without re-coding significant parts of the action mailer code.
  module MailTemplates
    def self.included(base)
      base.class_eval do
        alias_method_chain :template_path, :engine_additions
        alias_method_chain :render_message, :engine_additions
        alias_method_chain :render, :engine_additions
      end
    end

    private    
      # Returns all possible template paths for the current mailer
      def template_paths
        paths = Rails.plugins.by_precedence.map { |p| "#{p.root}/app/views/#{mailer_name}" }
        paths.unshift(template_path_without_engine_additions) unless Engines.disable_application_view_loading
        paths
      end
      
      # Return something that Dir[] can glob against
      def template_path_with_engine_additions
        "{#{template_paths.join(",")}}"
      end

      # Set the base_path for the ActionView::Base renderer to the correct path for the
      # given template
      def render_message_with_engine_additions(method_name, body)
        render_message_without_engine_additions(method_name, body)
      end
      
      # We've broken this up so that we can dynamically alter the base_path that ActionView
      # is rendering from so that templates can be located from plugins.
      def render_with_engine_additions(opts)
        template_path_for_method = Dir["#{template_path}/#{opts[:file]}.*"].first
        body = opts.delete(:body)
        i = initialize_template_class(body)
        i.base_path = File.dirname(template_path_for_method)
        i.render(opts)
      end
  end
end


::ActionView::Base.send(:include, Engines::RailsExtensions::Templates::ActionView)
::ActionController::Layout::ClassMethods.send(:include, Engines::RailsExtensions::Templates::Layout)
::ActionMailer::Base.send(:include, Engines::RailsExtensions::Templates::MailTemplates)