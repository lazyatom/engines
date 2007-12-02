module Engines
  module Assets    
    class << self      
      @@readme = %{Files in this directory are automatically generated from your Rails Engines.
They are copied from the 'public' directories of each engine into this directory
each time Rails starts (server, console... any time 'start_engine' is called).
Any edits you make will NOT persist across the next server restart; instead you
should edit the files within the <plugin_name>/assets/ directory itself.}     
       
      # Ensure that the plugin asset subdirectory of RAILS_ROOT/public exists, and
      # that we've added a little warning message to instruct developers not to mess with
      # the files inside, since they're automatically generated.
      def initialize_base_public_directory
        dir = Engines.public_directory
        unless File.exist?(dir)
          logger.debug "Creating public engine files directory '#{dir}'"
          FileUtils.mkdir(dir)
        end
        readme = File.join(dir, "README")        
        File.open(readme, 'w') { |f| f.puts @@readme } unless File.exist?(readme)
      end
    
      # Replicates the subdirectories under the plugins's +assets+ (or +public+) 
      # directory into the corresponding public directory. See also 
      # Plugin#public_directory for more.
      def mirror_files_for(plugin)
        return if plugin.public_directory.nil?
        begin 
          logger.debug "Attempting to copy plugin assets from '#{plugin.public_directory}' to '#{Engines.public_directory}'"
          mirror_files_from(plugin.public_directory, File.join(Engines.public_directory, plugin.name))      
        rescue Exception => e
          logger.warn "WARNING: Couldn't create the public file structure for plugin '#{plugin.name}'; Error follows:"
          logger.warn e
        end
      end
  
      # A general purpose method to mirror a directory (+source+) into a destination
      # directory, including all files and subdirectories. Files will not be mirrored
      # if they are identical already (checked via FileUtils#identical?).
      def mirror_files_from(source, destination)
        return unless File.directory?(source)
    
        # TODO: use Rake::FileList#pathmap?    
        source_files = Dir[source + "/**/*"]
        source_dirs = source_files.select { |d| File.directory?(d) }
        source_files -= source_dirs  
    
        source_dirs.each do |dir|
          # strip down these paths so we have simple, relative paths we can
          # add to the destination
          target_dir = File.join(destination, dir.gsub(source, ''))
          begin        
            FileUtils.mkdir_p(target_dir)
          rescue Exception => e
            raise "Could not create directory #{target_dir}: \n" + e
          end
        end

        source_files.each do |file|
          begin
            target = File.join(destination, file.gsub(source, ''))
            unless File.exist?(target) && FileUtils.identical?(file, target)
              FileUtils.cp(file, target)
            end 
          rescue Exception => e
            raise "Could not copy #{file} to #{target}: \n" + e 
          end
        end  
      end   
    end 
  end
end