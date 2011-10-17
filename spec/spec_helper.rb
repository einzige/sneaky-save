require "active_record"
require "logger"
require "rspec"
require "sneaky_save"

RSpec.configure { |config| config.mock_with :rspec }

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => "db/sqlite3.test.db")
ActiveRecord::Base.logger = Logger.new(STDOUT)
