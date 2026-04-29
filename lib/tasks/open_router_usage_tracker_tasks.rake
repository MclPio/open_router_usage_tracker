require "open_router_usage_tracker/maintenance/daily_summary_rebuilder"
require "open_router_usage_tracker/maintenance/raw_response_pruner"

namespace :open_router_usage_tracker do
  namespace :summaries do
    desc "Rebuild OpenRouterUsageTracker daily summaries from usage logs"
    task rebuild: :environment do
      rebuilt_count = OpenRouterUsageTracker::Maintenance::DailySummaryRebuilder.call
      puts "Rebuilt daily summaries from #{rebuilt_count} usage logs."
    end
  end

  namespace :raw_responses do
    desc "Prune raw usage responses before BEFORE=YYYY-MM-DD"
    task prune: :environment do
      before = Date.parse(ENV.fetch("BEFORE"))
      pruned_count = OpenRouterUsageTracker::Maintenance::RawResponsePruner.call(before: before)
      puts "Pruned raw responses from #{pruned_count} usage logs."
    end
  end
end
