module ActionController
  module Routing
    
    class << self
      # This holds the global list of valid controller paths
      attr_accessor :controller_paths
    end
    
    class ControllerComponent
      class << self
      protected
        def safe_load_paths #:nodoc:
          if defined?(RAILS_ROOT)
            paths = $LOAD_PATH.select do |base|
              base = File.expand_path(base)
              # Check that the path matches one of the allowed paths in controller_paths
              base.match(/^#{ActionController::Routing.controller_paths.map { |p| File.expand_path(p) } * '|'}/)
            end
            Engines.log.debug "Engines safe_load_paths: #{paths.inspect}"
            paths
          else
            $LOAD_PATH
          end
        end        
      end
    end
  end
end