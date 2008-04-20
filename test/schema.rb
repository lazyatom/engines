# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

puts "> Loading engines test application base schema"
ActiveRecord::Migration.verbose = ENV['VERBOSE'] || false

ActiveRecord::Schema.define(:version => 3) do

  %w(aardvarks accounts apples banjos clowns dogs elephants
     flowers gnomes igloos).each do |table_name|
    create_table table_name, :force => true do |t|
      t.string 'name'
    end
  end

end
