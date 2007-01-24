namespace :db do  
  namespace :fixtures do
    namespace :plugins do
      
      desc "Load plugin fixtures into the current environment's database."
      task :load => :environment do
        require 'active_record/fixtures'
        ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
        Dir.glob(File.join(RAILS_ROOT, 'vendor', 'plugins', ENV['PLUGIN'] || '**', 
                 'test', 'fixtures', '*.yml')).each do |fixture_file|
          Fixtures.create_fixtures(File.dirname(fixture_file), File.basename(fixture_file, '.*'))
        end
      end
      
    end
  end
end


# this is just a rip-off from the plugin stuff in railties/lib/tasks/documentation.rake, 
# because the default plugindoc stuff doesn't support subdirectories like <plugin>/app or
# <plugin>/component.
namespace :doc do

  plugins = FileList['vendor/plugins/**'].collect { |plugin| File.basename(plugin) }

  namespace :plugins do

    desc "Generate full documentation for all installed plugins"
    task :full => plugins.collect { |plugin| "doc:plugins:full:#{plugin}" }
    
    # documentation, including the app directory and any other source files 
    namespace :full do
      # Define doc tasks for each plugin
      plugins.each do |plugin|
        desc "Create plugin documentation for '#{plugin}'"
        task(plugin => :environment) do
          plugin_base   = RAILS_ROOT + "/vendor/plugins/#{plugin}"
          options       = []
          files         = Rake::FileList.new
          options << "-o doc/plugins/#{plugin}"
          options << "--title '#{plugin.titlecase} Plugin Documentation'"
          options << '--line-numbers' << '--inline-source'
          options << '-T html'

          files.include("#{plugin_base}/{lib,app}/**/*.rb") # this is the only addition!
          if File.exists?("#{plugin_base}/README")
            files.include("#{plugin_base}/README")    
            options << "--main '#{plugin_base}/README'"
          end
          files.include("#{plugin_base}/CHANGELOG") if File.exists?("#{plugin_base}/CHANGELOG")

          if files.empty?
            puts "No source files found in #{plugin_base}. No documentation will be generated."
          else
            options << files.to_s
            sh %(rdoc #{options * ' '})
          end
        end
      end
    end
  end
end



namespace :test do
  task :warn_about_multiple_plugin_testing_with_engines do
    puts %{-~============== A Moste Polite Warninge ===========================~-

You may experience issues testing multiple plugins at once when using
the code-mixing features that the engines plugin provides. If you do
experience any problems, please test plugins individually, i.e.

  $ rake test:plugins PLUGIN=my_plugin

or use the per-type plugin test tasks:

  $ rake test:plugins:units
  $ rake test:plugins:functionals
  $ rake test:plugins:integration

Report any issues on http://dev.rails-engines.org. Thanks!

-~===============( ... as you were ... )============================~-}
  end
  
  namespace :plugins do
    desc "Run all plugin unit tests"
    Rake::TestTask.new(:units => :setup_plugin_fixtures) do |t|
      t.pattern = "vendor/plugins/#{ENV['PLUGIN'] || "**"}/test/unit/**/*_test.rb"
      t.verbose = true
    end
    
    desc "Run all plugin functional tests"
    Rake::TestTask.new(:functionals => :setup_plugin_fixtures) do |t|
      t.pattern = "vendor/plugins/#{ENV['PLUGIN'] || "**"}/test/functional/**/*_test.rb"
      t.verbose = true
    end
    
    desc "Integration test engines"
    Rake::TestTask.new(:integration => :setup_plugin_fixtures) do |t|
      t.pattern = "vendor/plugins/#{ENV['PLUGIN'] || "**"}/test/integration/**/*_test.rb"
      t.verbose = true
    end

    desc "Run the plugin tests in vendor/plugins/**/test (or specify with PLUGIN=name)"
    task :all => [:warn_about_multiple_plugin_testing_with_engines, 
                  :units, :functionals, :integration]
    
    task :setup_plugin_fixtures => "db:test:prepare" do
      # mirror all fixtures into a temporary but known directory
      Engines::Testing.setup_plugin_fixtures
    end
  end  
end