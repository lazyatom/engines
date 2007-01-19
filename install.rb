$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "..", "rails", "railties", "lib")
silence_warnings { require 'rails/version' } # it may already be loaded.

unless Rails::VERSION::MAJOR >= 1 && Rails::VERSION::MINOR >= 2
  puts <<-end_of_warning
!!!=== IMPORTANT NOTE ===!!!
Support for Rails < 1.2 has been dropped; if you are using Rails =< 1.1.6, 
please use Engines 1.1.6, available from: 
  >>  http://svn.rails-engines.org/engines/tags/rel_1.1.6
For more details about changes in Engines 1.2, please see the changelog or: 
  >>  http://www.rails-engines.org
end_of_warning
else
  puts <<-end_of_message
Thanks for download the engines plugin. If you're upgrading to the 1.2.x 
branch of releases of this plugin, please ensure that you read and understand
the instructions in README and UPGRADING.'
end_of_message
end