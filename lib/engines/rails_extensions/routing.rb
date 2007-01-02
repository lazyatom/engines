module Engines::RailsExtensions::Routing
  def from_plugin(name)
    # At the point in which routing is loaded, we cannot guarantee that all
    # plugins are in Rails.plugins, so instead we need to use find_plugin_path
    path = Engines.find_plugin_path(name)
    routes_path = File.join(path, name.to_s, "routes.rb")
    logger.debug "loading routes from #{routes_path}"
    eval(IO.read(routes_path), binding, routes_path) if File.file?(routes_path)
  end
end

::ActionController::Routing::RouteSet::Mapper.send(:include, Engines::RailsExtensions::Routing)