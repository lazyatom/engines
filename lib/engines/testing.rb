require 'test/unit'
require 'test_help'

require 'tmpdir'
require 'fileutils'

module Engines::Testing
  mattr_accessor :temporary_fixtures_directory
  self.temporary_fixtures_directory = FileUtils.mkdir_p(File.join(Dir.tmpdir, "rails_fixtures"))
  
  # Called by the supplied testing rake tasks
  def self.setup_plugin_fixtures
    
    # Copy all plugin fixtures, and then the application fixtures, into this directory
    Rails.plugins.by_precedence do |plugin| 
      plugin_fixtures_directory =  File.join(plugin.root, "test", "fixtures")
      if File.directory?(plugin_fixtures_directory)
        Engines.mirror_files_from(plugin_fixtures_directory, self.temporary_fixtures_directory)
      end
    end
    Engines.mirror_files_from(File.join(RAILS_ROOT, "test", "fixtures"),
                              self.temporary_fixtures_directory)
  end
  
  def self.set_fixture_path
    Test::Unit::TestCase.fixture_path = self.temporary_fixtures_directory
    $LOAD_PATH.unshift self.temporary_fixtures_directory
  end
end