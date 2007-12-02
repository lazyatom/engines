class Module
  def default_attr_reader(name, default)
    define_method(name) do
      var = "@#{name}"
      unless instance_variable_defined?(var)
        instance_variable_set(var, default.is_a?(Symbol) ? send(default) : default)
      end
      instance_variable_get(var)
    end
  end
  
  def default_attr_accessor(name, default)
    default_attr_reader(name, default)
    attr_writer(name)
  end
end