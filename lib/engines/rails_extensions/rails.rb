# This is only here to allow for backwards compability with Engines that
# have been implemented based on Engines for Rails 1.2

module Rails
  def self.plugins
    Engines.plugins
  end
end
