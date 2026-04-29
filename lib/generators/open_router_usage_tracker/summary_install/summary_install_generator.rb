require "rails/generators"
require "rails/generators/migration"

module OpenRouterUsageTracker
  module Generators
    class SummaryInstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def self.next_migration_number(dir)
        [ Time.now.utc.strftime("%Y%m%d%H%M%S").to_i, current_migration_number(dir) + 1 ].max.to_s
      end

      def create_migration_file
        migration_template "migration.rb", "db/migrate/create_open_router_daily_summaries.rb"
      end
    end
  end
end
