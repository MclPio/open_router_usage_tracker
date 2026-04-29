source "https://rubygems.org"

# Specify your gem's dependencies in open_router_usage_tracker.gemspec.
gemspec

gem "rails", ENV["RAILS_VERSION"] unless ENV["RAILS_VERSION"].to_s.empty?

gem "pg", require: false if ENV["DB_ADAPTER"] == "postgresql"
gem "puma"

gem "sqlite3"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"
