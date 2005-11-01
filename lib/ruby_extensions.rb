#--
# Copyright (c) 2005 James Adam
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

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
  
  # A mechanism for defining configuration of Modules. With this
  # mechanism, default values for configuration can be provided within shareable
  # code, and the end user can customise the configuration without having to
  # provide all values.
  #
  # Example:
  #
  #  module MyModule
  #    config :param_one, "some value"
  #    config :param_two, 12345
  #  end
  #
  # Those values can now be accessed by the following method
  #
  #   MyModule.config :param_one  => "some value"
  #   MyModule.config :param_two  => 12345
  #
  # ... or, if you have overrriden the method 'config'
  #
  #   MyModule::CONFIG[:param_one]  => "some value"
  #   MyModule::CONFIG[:param_two]  => 12345
  #
  # Once a value is stored in the configuration, it will not be altered
  # by subsequent assignments, unless a special flag is given:
  #
  #   (later on in your code, most likely in another file)
  #   module MyModule
  #     config :param_one, "another value"
  #     config :param_two, 98765, :force
  #   end
  #
  # The configuration is now:
  #
  #   MyModule.config :param_one  => "some value" # not changed
  #   MyModule.config :param_two  => 98765
  #
  def config(name, value=nil, override=nil)
    if !self.const_defined?("CONFIG")
      self.class_eval("CONFIG = {}")
    end
    
    if value != nil
      if override or self::CONFIG[name] == nil
        self::CONFIG[name] = value 
      end
    else
      self::CONFIG[name]
    end
  end
end