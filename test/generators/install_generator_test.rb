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
end
