#--
# Add these methods to the top-level module so that they are available in all
# modules, etc
#++
class ::Module
  # Defines a constant within a module/class ONLY if that constant does
  # not already exist.
  #
  # This can be used to implement defaults in plugins/engines/libraries, e.g.
  # if a plugin module exists:
  #   module MyPlugin
  #     default_constant :MyDefault, "the_default_value"
  #   end
  #
  # then developers can override this default by defining that constant at
  # some point *before* the module/plugin gets loaded (such as environment.rb)
  def default_constant(name, value)
    if !self.const_defined?(name.to_s)
      self.class_eval("#{name.to_s} = #{value.inspect}")
    end
  end
end