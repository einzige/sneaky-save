require 'active_record'
require 'sqlite3'
require 'sneaky-save'

shared_context 'use connection', use_connection: true do
  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

  ActiveRecord::Schema.define do
    create_table 'fakes' do |table|
      table.column :name, :string, null: false
    end
  end

  class Fake < ActiveRecord::Base
    validates :name, presence: true

    before_save :before_save_callback

    def before_save_callback
      'BEFORE SAVE CALLED'
    end
  end
end


RSpec.configure do |config|
  config.mock_with :rspec
end
