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