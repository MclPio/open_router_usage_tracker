require "open_router_usage_tracker/version"
require "open_router_usage_tracker/engine"
require "open_router_usage_tracker/adapter/base"

module OpenRouterUsageTracker
  class << self
    attr_writer :configuration

    include Adapter::Base
  end
end
