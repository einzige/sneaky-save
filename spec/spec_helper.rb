require "active_record"
require "sqlite3"
require "sneaky-save"

shared_context "use connection", use_connection: true do
  ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

  ActiveRecord::Schema.define do
    create_table "fakes" do |table|
      table.column :name, :string, null: false
      table.column :belonger_id, :integer
      table.column :config, :text
    end

    create_table "belongers" do |table|
    end
  end

  class Belonger < ActiveRecord::Base
    has_many :fakes
  end

  class Fake < ActiveRecord::Base
    validates :name, presence: true

    before_save :before_save_callback

    belongs_to :belonger

    serialize :config, Hash

    def before_save_callback
      "BEFORE SAVE CALLED"
    end
  end
end


RSpec.configure do |config|
  config.mock_with :rspec
end
