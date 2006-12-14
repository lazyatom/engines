require 'engines'
require 'engines/extensions/rails'

puts "loading engines plugin"

# Store some information about the plugin subsystem
Rails.configuration = config

# We need a hook into this so we can get freaky with the plugin loading itself
Engines.rails_initializer = self

Engines.init

require 'engines/plugin'
require 'engines/extensions/rails_initializer'
