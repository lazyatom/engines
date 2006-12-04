class PluginSet < Set
  # Finds plugins with the set with the given name (accepts Strings or Symbols)
  def [](name)
    self.find { |plugin| plugin.name.to_s == name.to_s }
  end
end