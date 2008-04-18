require File.dirname(__FILE__) + '/../test_helper'

class ModelAndLibTest < Test::Unit::TestCase
  def test_rails_module_should_relay_to_engines_plugins
    assert_nothing_raised { Rails.plugins }
    assert_equal Engines.plugins, Rails.plugins 
  end
end