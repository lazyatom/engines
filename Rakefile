require 'rake'
require 'rake/rdoctask'

task :default => :doc

desc 'Generate documentation for the engines plugin.'
Rake::RDocTask.new(:doc) do |doc|
  doc.rdoc_dir = 'doc'
  doc.title    = 'Engines'
  doc.main     = "README"
  doc.rdoc_files.include("README", "UPGRADING", "CHANGELOG", "MIT-LICENSE")
  doc.rdoc_files.include('lib/**/*.rb')
  doc.options << '--line-numbers' << '--inline-source'
end