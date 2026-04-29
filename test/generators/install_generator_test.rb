require "test_helper"
require "generators/open_router_usage_tracker/install/install_generator"
require "generators/open_router_usage_tracker/summary_install/summary_install_generator"
require "generators/open_router_usage_tracker/upgrade_v2/upgrade_v2_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests OpenRouterUsageTracker::InstallGenerator
  destination Rails.root.join("tmp/generators") # A temporary place to generate files
  setup :prepare_destination

  test "generator creates a migration" do
    run_generator

    assert_migration "db/migrate/create_open_router_usage_logs.rb" do |migration|
      assert_match "create_table :open_router_usage_logs", migration
      assert_match "t.integer :input_tokens", migration
      assert_match "t.integer :output_tokens", migration
      assert_match "t.decimal :cost_amount", migration
      assert_match "t.json :usage_details", migration
      assert_match "t.datetime :occurred_at", migration
    end
  end

  test "summary generator creates a v2 daily summaries migration" do
    OpenRouterUsageTracker::Generators::SummaryInstallGenerator.start([], destination_root: destination_root)

    assert_migration "db/migrate/create_open_router_daily_summaries.rb" do |migration|
      assert_match "create_table :open_router_daily_summaries", migration
      assert_match "t.integer :input_tokens", migration
      assert_match "t.integer :output_tokens", migration
      assert_match "t.decimal :cost_amount", migration
      assert_match "t.json :usage_details", migration
    end
  end

  test "upgrade v2 generator creates a migration from v1 columns to v2 columns" do
    OpenRouterUsageTracker::Generators::UpgradeV2Generator.start([], destination_root: destination_root)

    assert_migration "db/migrate/upgrade_open_router_usage_tracker_to_v2.rb" do |migration|
      assert_match "rename_column :open_router_usage_logs, :prompt_tokens, :input_tokens", migration
      assert_match "rename_column :open_router_usage_logs, :completion_tokens, :output_tokens", migration
      assert_match "rename_column :open_router_usage_logs, :cost, :cost_amount", migration
      assert_match "add_column :open_router_usage_logs, :usage_details", migration
      assert_match "add_column :open_router_usage_logs, :occurred_at", migration
      assert_match "rename_column :open_router_daily_summaries, :prompt_tokens, :input_tokens", migration
      assert_match "add_column :open_router_daily_summaries, :usage_details", migration
      assert_equal 2, migration.scan("WHEN provider = 'open_router' AND cost_amount > 0 THEN 'provider'").size
      assert_equal 2, migration.scan("WHEN cost_amount > 0 THEN 'manual_response'").size
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

  test "upgrade v2 generator migration number advances past existing timestamps" do
    migration_dir = File.join(destination_root, "db/migrate")
    FileUtils.mkdir_p(migration_dir)
    File.write(File.join(migration_dir, "20990101000000_existing_migration.rb"), "")

    migration_number = OpenRouterUsageTracker::Generators::UpgradeV2Generator.next_migration_number(migration_dir)

    assert_equal "20990101000001", migration_number
  end

  test "all migration generators produce unique timestamps in one destination" do
    run_generator
    OpenRouterUsageTracker::Generators::SummaryInstallGenerator.start([], destination_root: destination_root)
    OpenRouterUsageTracker::Generators::UpgradeV2Generator.start([], destination_root: destination_root)

    migration_files = Dir[File.join(destination_root, "db/migrate/*.rb")].sort
    migration_numbers = migration_files.map { |file| File.basename(file).split("_", 2).first }

    assert_equal 3, migration_files.size
    assert_equal migration_numbers.uniq, migration_numbers
    assert_equal migration_numbers.sort, migration_numbers
  end
end
