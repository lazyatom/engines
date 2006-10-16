module Engines
  class << self
    # Returns the directory in which all engine public assets are mirrored.
    def public_engine_dir
      File.expand_path(File.join(RAILS_ROOT, "public", Engines.config(:public_dir)))
    end
  
    # create the /public/engine_files directory if it doesn't exist
    def initialize_base_public_directory
      if !File.exists?(public_engine_dir)
        # create the public/engines directory, with a warning message in it.
        Engines.log.debug "Creating public engine files directory '#{public_engine_dir}'"
        FileUtils.mkdir(public_engine_dir)
        File.open(File.join(public_engine_dir, "README"), "w") do |f|
          f.puts <<EOS
Files in this directory are automatically generated from your Rails Engines.
They are copied from the 'public' directories of each engine into this directory
each time Rails starts (server, console... any time 'start_engine' is called).
Any edits you make will NOT persist across the next server restart; instead you
should edit the files within the <engine_name>/public/ directory itself.
EOS
        end
      end
    end
  end  
end