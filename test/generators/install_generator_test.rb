require "test_helper"
require "generators/open_router_usage_tracker/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests OpenRouterUsageTracker::InstallGenerator
  destination Rails.root.join("tmp/generators") # A temporary place to generate files
  setup :prepare_destination

  test "generator creates a migration" do
    run_generator

    assert_migration "db/migrate/create_open_router_usage_logs.rb" do |migration|
      assert_match "create_table :open_router_usage_logs", migration
    end
  end

  test "generator creates an initializer" do
    run_generator

    assert_file "config/initializers/open_router_usage_tracker.rb" do |initializer|
      assert_match "OpenRouterUsageTracker.configure do |config|", initializer
      assert_match "config.user_foreign_key = :user_id", initializer
    end
  end
end
