require "open_router_usage_tracker/version"
require "open_router_usage_tracker/configuration"
require "open_router_usage_tracker/maintenance/daily_summary_rebuilder"
require "open_router_usage_tracker/maintenance/raw_response_pruner"
require "open_router_usage_tracker/engine"
require "open_router_usage_tracker/adapter/base"

module OpenRouterUsageTracker
  class << self
    attr_writer :configuration

    include Adapter::Base

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
