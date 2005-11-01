module ::ActionView
  class Base
    private
      def full_template_path(template_path, extension)

        # If the template exists in the normal application directory,
        # return that path
        default_template = "#{@base_path}/#{template_path}.#{extension}"
        return default_template if File.exist?(default_template)

        # Otherwise, check in the engines to see if the template can be found there.
        # Load this in order so that more recently started Engines will take priority.
        Engines::ActiveEngines.each do |engine|
          site_specific_path = File.join(engine.to_s, 'app', 'views',  template_path.to_s + '.' + extension.to_s)
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

        default = "/#{Engines.config(:public_dir)}/#{engine_name}/stylesheets/#{engine_name}.css"
        if defined?(RAILS_ROOT) && File.exists?("#{RAILS_ROOT}/public#{default}")
          new_sources << default
        end
        
        sources.each { |name| 
          new_sources << "/#{Engines.config(:public_dir)}/#{engine_name}/stylesheets/#{name}.css"
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
        
        default = "/#{Engines.config(:public_dir)}/#{engine_name}/javascripts/#{engine_name}.js"
        if defined?(RAILS_ROOT) && File.exists?("#{RAILS_ROOT}/public#{default}")
          new_sources << default
        end
        
        sources.each { |name| 
          new_sources << "/#{Engines.config(:public_dir)}/#{engine_name}/javascripts/#{name}.js"
        }
        new_sources << options
        javascript_include_tag(*new_sources)        
      end
    end
  end
end