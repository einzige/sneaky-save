# sneaky-save

[![Gem Version](https://badge.fury.io/rb/sneaky-save.png)](http://badge.fury.io/rb/sneaky-save)
[![Build Status](https://travis-ci.org/einzige/sneaky-save.png?branch=master)](https://travis-ci.org/einzige/sneaky-save)

ActiveRecord extension. Allows to save record without calling callbacks and validations.

## Installing
```
$ gem install sneaky-save
```

Or put in your gemfile for latest version:
```ruby
gem 'sneaky-save', git: 'git://github.com/einzige/sneaky-save.git'
```

## Using
```ruby
# Update. Returns true on success, false otherwise.
existing_record.sneaky_save

# Insert. Returns true on success, false otherwise.
Model.new.sneaky_save

# Raise exception on failure.
record.sneaky_save!
```

## Running specs
- Clone the repo
- run `bundle exec rake spec`

## Contributing to sneaky-save

- Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
- Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
- Fork the project
- Start a feature/bugfix branch
- Commit and push until you are happy with your contribution
- Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
- Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
