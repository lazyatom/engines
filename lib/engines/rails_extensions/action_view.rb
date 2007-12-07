# As well as providing code overloading for controllers and helpers 
# (see Engines::RailsExtensions::Dependencies), the engines plugin also allows
# developers to selectively override views and partials within their application.
#
# == An example
#
# This is achieved in much the same way as controller overriding. Our plugin contains
# a view to be rendered at the URL <tt>/test/hello</tt>, in 
# <tt>our_plugin/app/views/test/hello.rhtml</tt>:
#
#    <div class="greeting">Hi, <%= @dude.name %>, what's up?</div>
#
# If in a particular application we're not happy with this message, we can override
# it by replacing the partial in our own application - 
# <tt>RAILS_ROOT/app/views/test/hello.rhtml</tt>:
#
#     <div class="greeting custom_class">Wassup <%= @dude.name %>. 
#                                        Waaaaassaaaaaaaaup</div>
#
# This view will then be rendered in favour of that in the plugin.
#
module Engines::RailsExtensions::Templates
  
  # Override the finding of partials and views. This is achieved by wrapping
  # the (private) method #full_template_path_with_engine_additions, that checks
  # for the given template within plugins as well as the application.
  module ActionView
    def self.included(base) #:nodoc:
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
        Engines.plugins.by_precedence.each do |plugin|
          path_in_plugin = File.join(plugin.directory, 'app', 'views',  
                                     template_path.to_s + '.' + extension.to_s)
          return path_in_plugin if File.exist?(path_in_plugin)
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

  # The Layout module overrides a single (private) method in ActionController::Layout::ClassMethods,
  # called #layout_list. This method now returns an array of layouts, including those in plugins.
  module Layout
    def self.included(base) #:nodoc:
      base.class_eval { alias_method_chain :layout_list, :engine_additions }
    end

    private
      # Return the list of layouts, including any in the <tt>app/views/layouts</tt>
      # directories of loaded plugins.
      def layout_list_with_engine_additions
        plugin_layouts = Engines.plugins.by_precedence.map do |plugin|
          File.join(plugin.directory, "app", "views", "layouts")
        end
        layout_list_without_engine_additions + Dir["{#{plugin_layouts.join(",")}}/**/*"]
      end
      
  end
end

module ::ActionView
  class Base #:nodoc:
    include Engines::RailsExtensions::Templates::ActionView
  end
end

module ::ActionController #:nodoc:
  module Layout #:nodoc:
    module ClassMethods #:nodoc:
      include Engines::RailsExtensions::Templates::Layout
    end
  end
end