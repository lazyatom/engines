# add methods to handle including javascripts and stylesheets
module Engines::RailsExtensions::PublicAssetHelpers
  def self.included(base)
    base.class_eval do
      [:stylesheet_link_tag, :javascript_include_tag, :image_path, :image_tag].each do |m|
        alias_method_chain m, :engine_additions
      end
    end
  end
  
  def plugin_source_path(plugin_name, source)
    "/#{Rails.plugins[plugin_name].public_asset_directory}/#{source}"
  end
  
  def stylesheet_link_tag_with_engine_additions(*sources)
    stylesheet_link_tag_without_engine_additions(pluginify_sources("stylesheets", *sources))
  end
  
  def javascript_include_tag_with_engine_additions(*sources)
    javascript_include_tag_without_engine_additions(pluginify_sources("javascripts", *sources))
  end
  
  def image_path_with_engine_additions(source, options={})
    source = plugin_source_path(options[:plugin], "images", source) if options[:plugin]
  end
  
  def image_tag_with_engine_additions(source, options={})
  
  end
  
  private
    def pluginify_sources(type, *sources)
      options = sources.last.is_a?(Hash) ? sources.pop.stringify_keys : { }
      sources.map! { |s| plugin_source_path(options[:plugin], type, s) } if options[:plugin]
      sources << options # re-add options      
    end
  
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
      stylesheet_link_tag(*convert_public_sources(engine_name, :stylesheet, sources))
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
      javascript_include_tag(*convert_public_sources(engine_name, :javascript, sources))       
    end

    # Returns a image tag based on the parameters passed to it
    # Required option is option[:engine] in order to correctly idenfity the correct engine location
    #
    #   engine_image 'rails-engines.png', :engine => 'my_engine', :alt => 'My Engine' =>
    #   <img src="/engine_files/my_engine/images/rails-engines.png" alt="My Engine />
    #
    # Any options supplied as a Hash as the last argument will be processed as in
    # image_tag.
    #
    def engine_image(src, options = {})
    	return if !src

    	image_src = engine_image_src(src, options)

    	options.delete(:engine)

    	image_tag(image_src, options)
    end

    # Alias for engine_image
    def engine_image_tag(src, options = {})
      engine_image(src, options)
    end

    # Returns a path to the image stored within the engine_files
    # Required option is option[:engine] in order to correctly idenfity the correct engine location
    #
    #   engine_image_src 'rails-engines.png', :engine => 'my_engine' =>
    #   "/engine_files/my_engine/images/rails-engines.png"
    #
    def engine_image_src(src, options = {})
      "#{Engines.get(options[:engine].to_sym).asset_base_uri}/images/#{src}"
    end
    
    private
      # convert the engine public file sources into actual public paths
      # type:
      #   :stylesheet
      #   :javascript
      def convert_public_sources(engine_name, type, sources)
        options = sources.last.is_a?(Hash) ? sources.pop.stringify_keys : { }
        new_sources = []
      
        case type
          when :javascript
            type_dir = "javascripts"
            ext = "js"
          when :stylesheet
            type_dir = "stylesheets"
            ext = "css"
        end
        
        engine = Engines.get(engine_name)
        
        default = "#{engine.asset_base_uri}/#{type_dir}/#{engine_name}"
        if defined?(RAILS_ROOT) && File.exists?(File.join(RAILS_ROOT, "public", "#{default}.#{ext}"))
          new_sources << default
        end
      
        sources.each { |name| 
          new_sources << "#{engine.asset_base_uri}/#{type_dir}/#{name}"
        }

        new_sources << options         
      end
  end
end