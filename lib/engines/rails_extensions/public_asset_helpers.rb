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
    breakpoint
    javascript_include_tag_without_engine_additions(pluginify_sources("javascripts", *sources))
  end
  
  def image_path_with_engine_additions(source, options={})
    source = plugin_source_path(options[:plugin], "images", source) if options[:plugin]
    image_path_without_engine_additions(source, options)
  end
  
  def image_tag_with_engine_additions(source, options={})

  end
  
  private
    def pluginify_sources(type, *sources)
      options = sources.last.is_a?(Hash) ? sources.pop.stringify_keys : { }
      sources.map! { |s| plugin_source_path(options[:plugin], type, s) } if options[:plugin]
      sources << options # re-add options      
    end  
end