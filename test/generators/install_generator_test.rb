require "test_helper"
require "generators/open_router_usage_tracker/install/install_generator"
require "generators/open_router_usage_tracker/summary_install/summary_install_generator"

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

  test "install generator migration number advances past existing timestamps" do
    migration_dir = File.join(destination_root, "db/migrate")
    FileUtils.mkdir_p(migration_dir)
    File.write(File.join(migration_dir, "20990101000000_existing_migration.rb"), "")

    migration_number = OpenRouterUsageTracker::InstallGenerator.next_migration_number(migration_dir)

    assert_equal "20990101000001", migration_number
  end

  test "summary generator migration number advances past existing timestamps" do
    migration_dir = File.join(destination_root, "db/migrate")
    FileUtils.mkdir_p(migration_dir)
    File.write(File.join(migration_dir, "20990101000000_existing_migration.rb"), "")

    migration_number = OpenRouterUsageTracker::Generators::SummaryInstallGenerator.next_migration_number(migration_dir)

    assert_equal "20990101000001", migration_number
  end
end
