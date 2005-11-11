require 'fileutils'

module Test
  module Unit
    class TestCase  
      # Create a fixtures file based on the template file 
      # (<fixture_path>/templates/<fixture_template_name>.yml), and create a suitable
      # fixture file in the fixture_path directory to be loaded into the table given by
      # table_name.
      def self.set_fixtures_table(fixture_file_name, table_name)
        # presume that the template files are in fixture_path + "/templates"
        template_file = File.join(fixture_path, "templates", fixture_file_name.to_s + ".yml")
        destination_file = File.join(fixture_path, table_name.to_s + ".yml")
        if !File.exists?(template_file)
          raise "Cannot find fixture template file '#{template_file}'!"
        end
        # Copy the file across, unless the destination is identical.
        begin
          unless File.exist?(destination_file) && FileUtils.identical?(template_file, destination_file)
            FileUtils.cp(template_file, destination_file)
          end
        rescue Exception => e
          raise "Couldn't create fixture file: " + e
        end
      end
      
      # Returns any object from the given fixtures
      def fixture_object(fixture_name, object_name)
        send(fixture_name.to_sym, object_name)
      end
    end
  end
end