require File.dirname(__FILE__) + '/../test_helper'

class Ticket42Test < ActionController::TestCase
  tests AppAndPluginController

  def test_should_generate_form
    ActiveRecord::Migration.create_table :things do
    end
    
    get :form_test
    assert_select "form[action=/things]"
  end
end