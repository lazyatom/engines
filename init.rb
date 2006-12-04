require 'engines'

# Store some information about the plugin subsystem
Engines.rails_config = config
Engines.rails_initializer = self
#Engines.loaded_plugins = loaded_plugins

Engines.init

require 'engines/plugin'
require 'engines/extensions/rails_initializer'