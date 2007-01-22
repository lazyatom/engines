# Contains the enhancements to assist in testing plugins. See Engines::Testing
# for more details.

require 'test/unit'
require 'test_help'

require 'tmpdir'
require 'fileutils'

# In most cases, Rails' own plugin testing mechanisms are sufficient. However, there
# are cases where plugins can be given a helping hand in the testing arena. This module 
# contains some methods to assist when testing plugins that contain fixtures.
# 
# Since Rails' own fixtures method is fairly strict about where files can be loaded from,
# the simplest approach when running plugin tests with fixtures is to simply copy all
# fixtures into a single temporary location and inform the standard Rails mechanism to
# use this directory, rather than RAILS_ROOT/test/fixtures.
#
# The Engines::Testing#setup_plugin_fixtures method does this, copying all plugin fixtures
# into the temporary location before and tests are performed. This behaviour is invoked
# the the rake tasks provided by the Engines plugin, in the "test:plugins" namespace. If
# necessary, you can invoke the task manually.
#
# If you wish to take advantage of this, add a call to the Engines::Testing.set_fixture_path
# method somewhere before your tests (in a test_helper file, or above the TestCase itself).
module Engines::Testing
  mattr_accessor :temporary_fixtures_directory
  self.temporary_fixtures_directory = FileUtils.mkdir_p(File.join(Dir.tmpdir, "rails_fixtures"))
  
  # Copies fixtures from plugins and the application into a temporary directory 
  # (Engines::Testing.temporary_fixtures_directory). 
  # 
  # If a set of plugins is not given, fixtures are copied from all plugins in order 
  # of precedence, meaning that plugins can 'overwrite' the fixtures of others if they are 
  # loaded later; the application's fixtures are copied last, allowing any custom fixtures
  # to override those in the plugins. If no argument is given, plugins are loaded via
  # PluginList#by_precedence.
  #
  # This method is called by the engines-supplied plugin testing rake tasks
  def self.setup_plugin_fixtures(plugins=Rails.plugins.by_precedence)
    
    # Copy all plugin fixtures, and then the application fixtures, into this directory
    plugins.each do |plugin| 
      plugin_fixtures_directory =  File.join(plugin.root, "test", "fixtures")
      if File.directory?(plugin_fixtures_directory)
        Engines.mirror_files_from(plugin_fixtures_directory, self.temporary_fixtures_directory)
      end
    end
    Engines.mirror_files_from(File.join(RAILS_ROOT, "test", "fixtures"),
                              self.temporary_fixtures_directory)
  end
  
  # Sets the fixture path used by Test::Unit::TestCase to the temporary
  # directory which contains all plugin fixtures.
  def self.set_fixture_path
    Test::Unit::TestCase.fixture_path = self.temporary_fixtures_directory
    $LOAD_PATH.unshift self.temporary_fixtures_directory
  end
end