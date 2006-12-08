# In this file, we add some accessors to Rails in general, including mechanisms
# for accessing the loaded plugins and the configuration object

module ::Rails
  # The set of all loaded plugins
  mattr_accessor :plugins
  
  # The Rails::Initializer::Configuration object
  mattr_accessor :configuration
end
