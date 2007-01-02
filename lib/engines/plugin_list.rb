class PluginList < Array
  # Finds plugins with the set with the given name (accepts Strings or Symbols)
  def [](name_or_index)
    if name_or_index.is_a?(Fixnum)
      super
    else
      self.find { |plugin| plugin.name.to_s == name_or_index.to_s }
    end
  end
  
  # Go through each plugin, highest priority first (last loaded first).
  def in_precidence_order
    reverse
  end
end