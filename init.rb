# First, require the engines module & core methods
require "engines"

# Load this before we get actually start engines
require "engines/rails_extensions/rails_initializer"

# Start the engines mechanism.
Engines.init(config, self)

# Now that we've defined the engines module, load up any extensions
[:rails,
 :rails_initializer,
 :dependencies,
 :active_record,
 :migrations,
 :templates,
 :public_asset_helpers,
 :routing
].each do |f|
  require "engines/rails_extensions/#{f}"
end

# Load the testing extensions
require "engines/testing"