require 'rake'
require 'rake/rdoctask'

task :default => :doc

Rake::RDocTask.new(:doc) do |rd|
  rd.main = "README"
  rd.rdoc_dir = "doc"
  rd.rdoc_files.include("lib/**/*.rb")
  rd.rdoc_files.include("README", "CHANGELOG", "MIT-LICENSE", "UPGRADING")
  rd.options << "--line-numbers" << "--inline-source"
end