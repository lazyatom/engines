module Engines
  module RakeTasks
    def self.all_engines
      # An engine is informally defined as any subdirectory in vendor/plugins
      # which ends in '_engine', '_bundle', or contains an 'init_engine.rb' file.
      engine_base_dirs = ['vendor/plugins']
      # The engine root may be different; if possible try to include
      # those directories too
      if Engines.const_defined?(:CONFIG)
        engine_base_dirs << Engines::CONFIG[:root]
      end
      engine_base_dirs.map! {|d| [d + '/*_engine/*', 
                                  d + '/*_bundle/*',
                                  d + '/*/init_engine.rb']}.flatten!
      engine_dirs = FileList.new(*engine_base_dirs)
      engine_dirs.map do |engine| 
        File.basename(File.dirname(engine))
      end.uniq       
    end
  end
end


namespace :plugins do
  desc "Display version information about active engines"
  task :info => :environment do
    plugins = ENV["PLUGIN"] ? [Rails.plugins[ENV["PLUGINS"]]] : Rails.plugins
    plugins.each { |p|  puts "#{p.name}: #{p.version}" }
  end
end

namespace :db do  
  namespace :fixtures do
    namespace :plugins do
      
      desc "Load plugin fixtures into the current environment's database."
      task :load => :environment do
        require 'active_record/fixtures'
        ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
        plugin = ENV['ENGINE'] || '*'
        Dir.glob(File.join(RAILS_ROOT, 'vendor', 'plugins', plugin, 'test', 'fixtures', '*.yml')).each do |fixture_file|
          Fixtures.create_fixtures(File.dirname(fixture_file), File.basename(fixture_file, '.*'))
        end
      end
      
    end
  end
end


# this is just a rip-off from the plugin stuff in railties/lib/tasks/documentation.rake, 
# because the default plugindoc stuff doesn't support subdirectories like <engine>/app or
# <engine>/component.
namespace :doc do

  plugins = FileList['vendor/plugins/**'].collect { |plugin| File.basename(plugin) }

  namespace :plugins do
    # Define doc tasks for each plugin
    plugins.each do |plugin|
      desc "Create plugin documentation for '#{plugin}'"
      task(plugin => :environment) do
        plugin_base   = "vendor/plugins/#{plugin}"
        options       = []
        files         = Rake::FileList.new
        options << "-o doc/plugins/#{plugin}"
        options << "--title '#{plugin.titlecase} Plugin Documentation'"
        options << '--line-numbers' << '--inline-source'
        options << '-T html'

        files.include("#{plugin_base}/lib/**/*.rb")
        files.include("#{plugin_base}/app/**/*.rb") # this is the only addition!
        if File.exists?("#{plugin_base}/README")
          files.include("#{plugin_base}/README")    
          options << "--main '#{plugin_base}/README'"
        end
        files.include("#{plugin_base}/CHANGELOG") if File.exists?("#{plugin_base}/CHANGELOG")

        options << files.to_s

        sh %(rdoc #{options * ' '})
      end
    end
  end
end

namespace :test do
  desc "Run the plugin tests in vendor/plugins/**/test (or specify with PLUGIN=name)"
  Rake::TestTask.new(:plugins => [:environment, :warn_about_multiple_plugin_testing_with_engines]) do |t|
    t.libs << "test"
    t.pattern = "vendor/plugins/#{ENV['PLUGIN'] || '**'}/test/**/*_test.rb"
    t.verbose = true
  end

  task :warn_about_multiple_plugin_testing_with_engines do
    puts %{
-~============== A Moste Polite Warninge ===========================~-
You may experience issues testing multiple plugins at once when using
the code-mixing features that the engines plugin provides. If you do
experience any problems, please test plugins individually, and report
any issues on http://dev.rails-engines.org. Thanks!
-~===============( ... as you were ... )============================~-
}
  end
end