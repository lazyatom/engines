#--
# Copyright (c) 2004 David Heinemeier Hansson

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Engine Hacks by James Adam, 2005.
#++

module ::Dependencies
  def require_or_load(file_name)
    # try and load the framework code first
    # can't use model, as there's nothing in the name to indicate that the file is a 'model' file
    # rather than a library or anything else.
    ['controller', 'helper'].each do |type| 
      if file_name.include?('_' + type)
        # load in reverse order, so most recently started Engines take precidence
        Engines::ActiveEngines.reverse.each do |engine|
          engine_file_name = File.join(engine, 'app', "#{type}s",  File.basename(file_name))
          if File.exist? engine_file_name
            load? ? load(engine_file_name) : require(engine_file_name)
          end
        end
      end
    end

    # finally, load any application-specific controller classes.
    file_name = "#{file_name}.rb" unless ! load? || file_name [-3..-1] == '.rb'
    load? ? load(file_name) : require(file_name)
  end

  class RootLoadingModule < LoadingModule
    # hack to allow adding to the load paths within the Rails Dependencies mechanism.
    # this allows Engine classes to be unloaded and loaded along with standard
    # Rails application classes.
    def add_path(path)
      @load_paths << (path.kind_of?(ConstantLoadPath) ? path : ConstantLoadPath.new(path))
    end
  end
end