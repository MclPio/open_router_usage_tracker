require "rails/generators"
require "rails/generators/migration"

module OpenRouterUsageTracker
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path("templates", __dir__)

    def self.next_migration_number(dir)
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    end

    def create_files
      migration_template "migration.rb", "db/migrate/create_open_router_usage_logs.rb"
    end
  end
end
