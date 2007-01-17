begin

  $LOAD_PATH.unshift File.join("..", "..", "rails", "railties", "lib")
  require 'rails/version'

  if Rails::VERSION::MAJOR < 1 && Rails::VERSION::MINOR < 2
    puts <<-end_of_warning
!!!=== IMPORTANT NOTE ===!!!
Support for Rails < 1.2 has been dropped; if you are using Rails =< 1.1.6, 
please use Engines 1.1.6, available from: 
  >>  http://svn.rails-engines.org/engines/tags/rel_1.1.6
For more details about changes in Engines 1.2, please see the changelog or: 
  >>  http://www.rails-engines.org
  end_of_warning
  end

rescue # ... we couldn't detect the Rails version. Oh well.
end

puts <<-end_of_message
Thanks for download the engines plugin. If you're upgrading to the 1.2.x 
branch of releases of this plugin, please ensure that you read and understand
the contents of the UPGRADING file.'
end_of_message
