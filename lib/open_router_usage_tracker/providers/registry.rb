require "open_router_usage_tracker/providers/open_ai/parser"
require "open_router_usage_tracker/providers/open_router/parser"
require "open_router_usage_tracker/providers/google/parser"
require "open_router_usage_tracker/providers/anthropic/parser"
require "open_router_usage_tracker/providers/x_ai/parser"

module OpenRouterUsageTracker
  module Providers
    PARSERS = {
      "open_ai" => OpenAi::Parser,
      "open_router" => OpenRouter::Parser,
      "google" => Google::Parser,
      "anthropic" => Anthropic::Parser,
      "x_ai" => XAi::Parser
    }.freeze

    SUPPORTED_PROVIDER_NAMES = PARSERS.keys.freeze

    def self.supported_provider_names
      SUPPORTED_PROVIDER_NAMES
    end

    def self.parser_for(provider)
      PARSERS.fetch(provider) do
        raise ArgumentError, "Unsupported provider: #{provider}. Supported providers are: #{supported_provider_names.join(', ')}"
      end
    end
  end
end
