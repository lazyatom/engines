# The way ActionMailer is coded in terms of finding templates is very restrictive, to the point
# where all templates for rendering must exist under the single base path. This is difficult to
# work around without re-coding significant parts of the action mailer code.
#
# ---
#
# The MailTemplates module overrides two (private) methods from ActionMailer to enable mail 
# templates within plugins:
#
# [+template_path+]  which now produces the contents of #template_paths
# [+render+]         which now find the first matching template and creates an ActionVew::Base
#                    instance with the correct @base_path for that template

module Engines::RailsExt::ActionMailer
  module Base
    def self.included(base) #:nodoc:
      base.class_eval do
        # TODO commented this out because it seems to break ActionMailer
        # how can this be fixed?
        
        # alias_method_chain :template_path, :engine_additions
        alias_method_chain :render, :engine_additions
      end
    end

    private    
      # Returns all possible template paths for the current mailer, including those
      # within the loaded plugins.
      def template_paths
        paths = Engines.plugins.by_precedence.map { |p| "#{p.directory}/app/views/#{mailer_name}" }
        paths.unshift(template_path_without_engine_additions) unless Engines.disable_application_view_loading
        paths
      end

      # Return something that Dir[] can glob against. This method is called in 
      # ActionMailer::Base#create! and used as part of an argument to Dir. We can
      # take advantage of this by using some of the features of Dir.glob to search
      # multiple paths for matching files.
      def template_path_with_engine_additions
        "{#{template_paths.join(",")}}"
      end

      # We've broken this up so that we can dynamically alter the base_path that ActionView
      # is rendering from so that templates can be located from plugins.
      def render_with_engine_additions(opts)
        template_path_for_method = Dir["#{template_path}/#{opts[:file]}*"].first
        body = opts.delete(:body)
        i = initialize_template_class(body)
        i.base_path = File.dirname(template_path_for_method)
        i.render(opts)
      end
      
    # We don't need to do this if ActionMailer hasn't been loaded.
    ActionMailer::Base.send :include, self if Object.const_defined?(:ActionMailer)      
  end
end