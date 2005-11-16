desc "Migrate one or all engines, based on the migrations in that engines db/migrate dir"
task :engine_migrate => :environment do
  engines_to_migrate = Engines::ActiveEngines
  fail = false
  if ENV["ENGINE"]
    engines_to_migrate = [Engines.get(ENV["ENGINE"])].compact
    if engines_to_migrate.empty?
      puts "Couldn't find an engine called '#{ENV["ENGINE"]}'"
      fail = true
    end
  elsif ENV["VERSION"]
    # ignore the VERSION, since it makes no sense in this context; we wouldn't
    # want to revert ALL engines to the same version because of a misttype
    puts "Ignoring the given version (#{ENV["VERSION"]})."
    puts "To control individual engine versions, use the ENGINE=<engine> argument"
    fail = true
  end

  if !fail
    engines_to_migrate.each do |engine| 
      Engines::EngineMigrator.current_engine = engine
      migration_directory = File.join(RAILS_ROOT, engine.root, 'db', 'migrate')
      if File.exist?(migration_directory)
        puts "Migrating engine '#{engine.name}'"
        Engines::EngineMigrator.migrate(migration_directory, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
        Rake::Task[:db_schema_dump].invoke if ActiveRecord::Base.schema_format == :ruby
      else
        puts "The db/migrate directory for engine '#{engine.name}' appears to be missing."
        puts "Should be: #{migration_directory}"
      end
    end
  end
end