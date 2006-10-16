module Engines
  # We need to know the version of Rails that we are running before we
  # can override any of the dependency stuff, since Rails' own behaviour
  # has changed over the various releases. We need to explicily make sure
  # that the Rails::VERSION constant is loaded, because such things could
  # not automatically be achieved prior to 1.1, and the location of the
  # file moved in 1.1.1!
  def detect_rails_version
    # At this point, we can't even rely on RAILS_ROOT existing, so we have to figure
    # the path to RAILS_ROOT/vendor/rails manually
    rails_root = File.expand_path(
      File.join(File.dirname(__FILE__), # RAILS_ROOT/vendor/plugins/engines/lib
      '..', # RAILS_ROOT/vendor/plugins/engines
      '..', # RAILS_ROOT/vendor/plugins
      '..', # RAILS_ROOT/vendor
      'rails', 'railties', 'lib')) # RAILS_ROOT/vendor/rails/railties/lib
      
    begin
      load File.join(rails_root, 'rails', 'version.rb')

    rescue MissingSourceFile # this means they DON'T have Rails 1.1.1 or later installed in vendor
      begin
        load File.join(rails_root, 'rails_version.rb')

      rescue MissingSourceFile # this means they DON'T have Rails 1.1.0 or previous installed in vendor
        begin
          # try and load version information for Rails 1.1.1 or later from the $LOAD_PATH
          require 'rails/version'

        rescue LoadError
          # try and load version information for Rails 1.1.0 or previous from the $LOAD_PATH
          require 'rails_version'

        end
      end
    end
  end
  
  def on_edge?
    config(:edge) == true
  end
    
  def on_rails_1_1?
    Rails::VERSION::STRING =~ /\A1.1/
  end
  
  def on_rails_1_0?
    Rails::VERSION::STRING =~ /\A1.0/
  end
end