require "open_router_usage_tracker/version"
require "open_router_usage_tracker/railtie"
require "open_router_usage_tracker/configuration"

module OpenRouterUsageTracker
  class << self
    attr_writer :configuration
  end

  # This is the method that provides access to the config object.
  def self.configuration
    @configuration ||= Configuration.new
  end

  # This is the `configure` block that will be used in the initializer.
  def self.configure
    yield(configuration)
  end

  def log
    puts "Hello World"
  end
end
