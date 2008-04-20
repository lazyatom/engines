require 'rake'
require 'rake/rdoctask'
require 'tmpdir'

task :default => :doc

desc 'Generate documentation for the engines plugin.'
Rake::RDocTask.new(:doc) do |doc|
  doc.rdoc_dir = 'doc'
  doc.title    = 'Engines'
  doc.main     = "README"
  doc.rdoc_files.include("README", "CHANGELOG", "MIT-LICENSE")
  doc.rdoc_files.include('lib/**/*.rb')
  doc.options << '--line-numbers' << '--inline-source'
end

desc 'Run the engine plugin tests within their test harness'
task :cruise do
  # checkout the project into a temporary directory
  version = "rails_2.0"
  test_dir = "#{Dir.tmpdir}/engines_plugin_#{version}_test"
  puts "Checking out test harness for #{version} into #{test_dir}"
  `svn co http://svn.rails-engines.org/test/engines/#{version} #{test_dir}`

  # run all the tests in this project
  Dir.chdir(test_dir)
  load 'Rakefile'
  puts "Running all tests in test harness"
  ['db:migrate', 'test', 'test:plugins'].each do |t|
    Rake::Task[t].invoke
  end  
end

namespace :test do
  
  def test_app_dir
    File.join(File.dirname(__FILE__), 'test_app')
  end
    
  task :clean do
    FileUtils.rm_r(test_app_dir) if File.exist?(test_app_dir)
  end
  
  task :generate_app do
    # if ENV['edge']
    #   vendor_dir = File.join(test_app_dir, 'vendor')
    #   FileUtils.mkdir_p vendor_dir
    #   system "cd #{vendor_dir} && git clone --depth 1 git://github.com/rails/rails.git"
    #   system "ruby #{File.join(vendor_dir, 'rails', 'railties', 'bin', 'rails')} #{test_app_dir}"
    # else
    #   system "rails #{test_app_dir}"
    # end
    
    # offline fix for getting rails
    vendor_dir = File.join(test_app_dir, 'vendor')
    FileUtils.mkdir_p vendor_dir
    system "cd #{vendor_dir} && ln -s /Users/james/Code/rails/git/rails rails"
    system "ruby #{File.join(vendor_dir, 'rails', 'railties', 'bin', 'rails')} #{test_app_dir}"
    
    # get the database config and schema in place
    require 'yaml'
    File.open(File.join(test_app_dir, 'config', 'database.yml'), 'w') do |f|
      f.write({
        "development" => {"adapter" => "sqlite3", "database" => "engines_development.sqlite3"},
        "test"        => {"adapter" => "sqlite3", "database" => "engines_test.sqlite3"}
      }.to_yaml)
    end
    FileUtils.cp(File.join(File.dirname(__FILE__), *%w[test schema.rb]), 
                 File.join(test_app_dir, 'db'))
  end
  
  # We can't link the plugin, as it needs to be present for script/generate to find
  # the plugin generator.
  # TODO: find and +1/create issue for loading generators from symlinked plugins
  desc 'Mirror the engines plugin into the test application'
  task :copy_engines_plugin do
    engines_plugin = File.join(test_app_dir, "vendor", "plugins", "engines")
    FileUtils.rm_r(engines_plugin) if File.exist?(engines_plugin)
    FileUtils.mkdir_p(engines_plugin)
    FileList["*"].exclude("test_app").each do |file|
      FileUtils.cp_r(file, engines_plugin)
    end
  end
  
  # desc 'Ensure helper methods used by the engines plugin test suite are available'
  # task :append_engines_test_helper do
  #   engines_test_helper_line = "require 'engines_test_helper'"
  #   
  #   test_helper_rb = File.join(test_app_dir, "test", "test_helper.rb")
  #   test_helper_lines = File.readlines(test_helper_rb)
  #   
  #   return if test_helper_lines.include?(engines_test_helper_line)
  #   
  #   test_helper_lines << engines_test_helper_line
  #   File.open(test_helper_rb, 'w') { |f| f.write test_helper_lines }
  # end
  # 
  # desc 'Add the engines bootstrap line to the environment.rb file if it is missing'
  # task :insert_engines_boot_loader_line do
  #   engines_boot_line = "require File.join(File.dirname(__FILE__), '../vendor/plugins/engines/boot')"
  #   
  #   environment_rb_file = File.join(test_app_dir, 'config', 'environment.rb')
  #   environment_rb_lines = File.readlines(environment_rb_file)
  #   return if environment_rb_lines.include?(engines_boot_line)
  #   
  #   first_initializer_line = environment_rb_lines.find { |line| line =~ /\ARails::Initializer/ }
  #   index = environment_rb_lines.index(first_initializer_line)
  #   environment_rb_lines.insert(index, engines_boot_line + "\n\n")
  #   File.open(environment_rb_file, 'w') { |f| f.write environment_rb_lines }
  # end
  
  def insert_line(line, options)
    line = line + "\n"
    target_file = File.join(test_app_dir, options[:into])
    lines = File.readlines(target_file)
    return if lines.include?(line)
    
    if options[:after]
      if options[:after].is_a?(String)
        after_line = options[:after] + "\n"
      else
        after_line = lines.find { |l| l =~ options[:after] }
        raise "couldn't find a line matching #{options[:after].inspect} in #{target_file}" unless after_line
      end
      index = lines.index(after_line)
      raise "couldn't find line '#{after_line}' in #{target_file}" unless index
      lines.insert(index + 1, line)
    else
      lines << line
    end
    File.open(target_file, 'w') { |f| f.write lines.join }
  end
  
  def mirror_test_files(src, dest=nil)
    destination_dir = File.join(*([test_app_dir, dest].compact))
    FileUtils.cp_r(File.join(File.dirname(__FILE__), 'test', src), destination_dir)
  end
  
  desc 'Update the plugin and tests files in the test application from the plugin'
  task :mirror_engine_files => [:copy_engines_plugin] do
    
    insert_line("require File.join(File.dirname(__FILE__), '../vendor/plugins/engines/boot')",
                :into => 'config/environment.rb',
                :after => "require File.join(File.dirname(__FILE__), 'boot')")
                
    insert_line('map.from_plugin :test_routing', :into => 'config/routes.rb', 
                :after => /\AActionController::Routing::Routes/)
                
    insert_line("require 'engines_test_helper'", :into => 'test/test_helper.rb')
    
    mirror_test_files('app')
    mirror_test_files('lib')
    mirror_test_files('plugins', 'vendor')
    mirror_test_files('unit', 'test')
    mirror_test_files('functional', 'test')
  end
  
  desc 'Prepare the engines test environment'
  task :prepare => [:clean, :generate_app, :mirror_engine_files]
end

task :test => "test:prepare" do
  exec("cd #{test_app_dir} && rake db:schema:load && rake")
end
