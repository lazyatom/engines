require 'engines'

# Store some information about the plugin subsystem
Engines.rails_config = config
Engines.rails_initializer = self

Engines.init

require 'engines/plugin'
require 'engines/extensions/rails_initializer'