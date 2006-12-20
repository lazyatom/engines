require "engines/rails_extensions/public_asset_helpers"

module Engines::RailsExtensions::ActionView
  def self.included(base)
    base.class_eval { alias_method_chain :full_template_path, :engine_additions }
  end

  private
    def full_template_path_with_engine_additions(template_path, extension)
      # The template path as Rails would expect it
      default_template_path = full_template_path_without_engine_additions(template_path, extensions)

      # There are some circumstances where we don't want to load views from plugins
      return default_template_path if Engines.disable_app_views_loading

      # Otherwise, check in the engines to see if the template can be found there.
      # Load this in order so that more recently started Engines will take priority.
      Rails.plugins.reverse.each do |plugin|
        plugin_specific_path = File.join(plugin.root, 'app', 'views',  
                                       template_path.to_s + '.' + extension.to_s)
        return plugin_specific_path if File.exist?(plugin_specific_path)
      end

      # If it cannot be found anywhere, return the default path, where the
      # user *should* have put it.  
      return default_template_path         
    end  
end

::ActionView::Base.send(:include, Engines::RailsExtensions::ActionView)
::ActionView::Helpers::AssetTagHelper.send(:include, Engines::RailsExtensions::PublicAssetHelpers)