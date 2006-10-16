module Engines
  class << self
    # create the public engine asset directory if it doesn't exist
    # (see Engines.public_dir for the specific location)
    def initialize_base_public_directory
      if !File.exists?(Engines.public_dir)
        # create the public/engines directory, with a warning message in it.
        Engines.log.debug "Creating public engine files directory '#{Engines.public_dir}'"
        FileUtils.mkdir(Engines.public_dir)
        File.open(File.join(Engines.public_dir, "README"), "w") do |f|
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