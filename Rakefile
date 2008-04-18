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
  
  def mirror_test_files(src, dest=nil)
    destination_dir = File.join(*([test_app_dir, dest].compact))
    FileUtils.cp_r(File.join(File.dirname(__FILE__), 'test', src), destination_dir)
  end
  
  def append_engines_test_helper
    File.open(File.join(test_app_dir, *%w[test test_helper.rb]), 'a') do |f|
      f.puts # a blank line
      f.puts "require 'engines_test_helper'"
    end
  end
  
  def link_engines_plugin
    system "ln -s #{File.expand_path(File.dirname(__FILE__))} #{test_app_dir}/vendor/plugins/engines"
  end
  
  def insert_engines_boot_loader_line
    environment_rb_file = File.join(test_app_dir, 'config', 'environment.rb')
    environment_rb_lines = File.readlines(environment_rb_file)
    first_initializer_line = environment_rb_lines.find { |line| line =~ /\ARails::Initializer/ }
    index = environment_rb_lines.index(first_initializer_line)
    environment_rb_lines.insert(index, "require File.join(File.dirname(__FILE__), '../vendor/plugins/engines/boot')\n")
    File.open(environment_rb_file, 'w') { |f| f.write environment_rb_lines.join("\n") }
  end
  
  def create_database_yml
    File.open(File.join(test_app_dir, 'config', 'database.yml'), 'w') do |f|
      f.write <<-YML
development:
  adapter: sqlite3
  database: engines_development.sqlite3
test:
  adapter: sqlite3
  database: engines_test.sqlite3
      YML
    end
  end
  
  task :clean do
    FileUtils.rm_r(test_app_dir) if File.exist?(test_app_dir)
  end
  
  task :generate_app do
    if ENV['edge']
      vendor_dir = File.join(test_app_dir, 'vendor')
      FileUtils.mkdir_p vendor_dir
      system "cd #{vendor_dir} && git clone --depth 1 git://github.com/rails/rails.git"
      system "ruby #{File.join(vendor_dir, 'rails', 'railties', 'bin', 'rails')} #{test_app_dir}"
    else
      system "rails #{test_app_dir}"
    end
  end
  
  task :prepare_app do
    mirror_test_files('app')
    mirror_test_files('lib')
    mirror_test_files('plugins', 'vendor')
    mirror_test_files('unit', 'test')
    mirror_test_files('functional', 'test')
    append_engines_test_helper
    link_engines_plugin
    insert_engines_boot_loader_line
    create_database_yml
    FileUtils.cp(File.join(File.dirname(__FILE__), *%w[test schema.rb]), 
                 File.join(test_app_dir, 'db'))
    system "cd #{test_app_dir} && rake db:schema:load"
  end
  
  desc 'Prepare the engines test environment'
  task :prepare => [:clean, :generate_app, :prepare_app]
end