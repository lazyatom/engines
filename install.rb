# TODO
#
#  * add upgrade path from engines 1.1.x

unless Rails::VERSION::MAJOR >= 1 
  unless Rails::VERSION::MINOR >= 2
    puts <<-end_of_warning
!!!=== IMPORTANT NOTE ===!!!
Support for Rails < 1.2 has been dropped; if you are using Rails =< 1.1.6, please use Engines 1.1.6, available from http://svn.rails-engines.org/engines/tags/rel_1.1.6
For more details about changes in Engines 1.2, please see the changelog or http://www.rails-engines.org
end_of_warning
  end
end