class TestMigration < ActiveRecord::Migration
  def self.up
    self.down
    create_table(:fakes) { |t| t.string :name }
  end

  def self.down
    drop_table :fakes if ActiveRecord::Base.connection.tables.include? :fakes
  end
end
TestMigration.up

class Fake < ActiveRecord::Base
  validates_presence_of :name

  before_save :before_save_callback

  def before_save_callback
    puts "BEFORE SAVE CALLED"
  end
end
