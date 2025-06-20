# lib/open_router_usage_tracker/engine.rb

require "rails/engine"

module OpenRouterUsageTracker
  class Engine < ::Rails::Engine
    initializer "open_router_usage_tracker.migrations" do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
