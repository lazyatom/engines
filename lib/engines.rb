require 'ActiveSupport'
require File.join(File.dirname(__FILE__), 'engines/plugin')
require File.join(File.dirname(__FILE__), 'engines/plugin/list')
require File.join(File.dirname(__FILE__), 'engines/plugin/loader')
require File.join(File.dirname(__FILE__), 'engines/plugin/locator')
require File.join(File.dirname(__FILE__), 'engines/assets')

# == Parameters
#
# The Engines module has a number of public configuration parameters:
#
# [+public_directory+]  The directory into which plugin assets should be
#                       mirrored. Defaults to <tt>RAILS_ROOT/public/plugin_assets</tt>.
# [+schema_info_table+] The table to use when storing plugin migration 
#                       version information. Defaults to +plugin_schema_info+.
#
# Additionally, there are a few flags which control the behaviour of
# some of the features the engines plugin adds to Rails:
#
# [+disable_application_view_loading+] A boolean flag determining whether
#                                      or not views should be loaded from 
#                                      the main <tt>app/views</tt> directory.
#                                      Defaults to false; probably only 
#                                      useful when testing your plugin.
# [+disable_application_code_loading+] A boolean flag determining whether
#                                      or not to load controllers/helpers 
#                                      from the main +app+ directory,
#                                      if corresponding code exists within 
#                                      a plugin. Defaults to false; again, 
#                                      probably only useful when testing 
#                                      your plugin.
# [+disable_code_mixing+] A boolean flag indicating whether all plugin
#                         copies of a particular controller/helper should 
#                         be loaded and allowed to override each other, 
#                         or if the first matching file should be loaded 
#                         instead. Defaults to false.
#
module Engines
  # The set of all loaded plugins
  mattr_accessor :plugins
  self.plugins = Engines::Plugin::List.new  
  
  # List of extensions to load, can be changed in init.rb before calling Engines.init
  mattr_accessor :extensions
  self.extensions = %w(active_record action_mailer action_view asset_helpers routing migrations dependencies)
  
  # The name of the public directory to mirror public engine assets into.
  # Defaults to <tt>RAILS_ROOT/public/plugin_assets</tt>.
  mattr_accessor :public_directory
  self.public_directory = File.join(RAILS_ROOT, 'public', 'plugin_assets')

  # The table in which to store plugin schema information. Defaults to
  # "plugin_schema_info".
  mattr_accessor :schema_info_table
  self.schema_info_table = "plugin_schema_info"

  #--
  # These attributes control the behaviour of the engines extensions
  #++
  
  # Set this to true if views should *only* be loaded from plugins
  mattr_accessor :disable_application_view_loading
  self.disable_application_view_loading = false
  
  # Set this to true if controller/helper code shouldn't be loaded 
  # from the application
  mattr_accessor :disable_application_code_loading
  self.disable_application_code_loading = false
  
  # Set this ti true if code should not be mixed (i.e. it will be loaded
  # from the first valid path on $LOAD_PATH)
  mattr_accessor :disable_code_mixing
  self.disable_code_mixing = false
  
  class << self
    def init
      load_extensions
      Engines::Assets.initialize_base_public_directory
    end
    
    def load_extensions
      @@extensions.each { |name| require "engines/rails_ext/#{name}" }
      # load the testing extensions, if we are in the test environment.
      require "engines/testing" if RAILS_ENV == "test"
    end
    
    def select_existing_paths(paths)
      paths.select { |path| File.directory?(path) }
    end  
  end  
end