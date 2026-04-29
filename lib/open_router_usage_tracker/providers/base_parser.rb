require "open_router_usage_tracker/normalized_usage"

module OpenRouterUsageTracker
  module Providers
    class BaseParser
      class << self
        private

        def normalized_usage(...)
          OpenRouterUsageTracker::NormalizedUsage.new(...)
        end

        def required_path(response, *path)
          value = path_value(response, *path)
          return value unless missing?(value)

          raise OpenRouterUsageTracker::ParseError, "Missing required provider response key: #{path.join('.')}"
        end

        def optional_path(response, *path)
          path_value(response, *path)
        end

        def required_hash(response, *path)
          value = required_path(response, *path)
          return value if value.is_a?(Hash)

          raise OpenRouterUsageTracker::ParseError, "Invalid provider response key #{path.join('.')}: must be an Object"
        end

        def required_integer(response, *path)
          to_integer(required_path(response, *path), field: path.join("."))
        end

        def optional_integer(response, *path)
          value = optional_path(response, *path)
          value.nil? ? nil : to_integer(value, field: path.join("."))
        end

        def optional_number(response, *path)
          value = optional_path(response, *path)
          value.nil? ? nil : to_number(value, field: path.join("."))
        end

        def cost_attributes(response, source:, currency: nil)
          cost = optional_number(response, "usage", "cost")

          if cost.nil?
            { cost_amount: 0.0, cost_currency: nil, cost_source: "none" }
          else
            { cost_amount: cost, cost_currency: currency, cost_source: source }
          end
        end

        def required_token_count(response, paths:, field:)
          to_integer(first_present(response, paths, field: field), field: field)
        end

        def optional_token_count(response, paths:, field:)
          paths.each do |path|
            value = optional_path(response, *path)
            return to_integer(value, field: field) unless missing?(value)
          end

          nil
        end

        def first_present(response, paths, field:)
          paths.each do |path|
            value = optional_path(response, *path)
            return value unless missing?(value)
          end

          raise OpenRouterUsageTracker::ParseError, "Missing required provider response key: #{field}"
        end

        def compact_details(details)
          details.each_with_object({}) do |(key, value), compacted|
            compacted[key] = value unless value.nil?
          end
        end

        def path_value(response, *path)
          path.reduce(response) do |current, key|
            return nil unless current.respond_to?(:key?)

            fetch_key(current, key)
          end
        end

        def fetch_key(hash, key)
          return hash[key] if hash.key?(key)

          alternate_key = key.is_a?(String) ? key.to_sym : key.to_s
          hash[alternate_key] if hash.key?(alternate_key)
        end

        def missing?(value)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end

        def to_integer(value, field:)
          Integer(value)
        rescue ArgumentError, TypeError
          raise OpenRouterUsageTracker::ParseError, "Invalid provider response key #{field}: must be an Integer"
        end

        def to_number(value, field:)
          Float(value)
        rescue ArgumentError, TypeError
          raise OpenRouterUsageTracker::ParseError, "Invalid provider response key #{field}: must be numeric"
        end
      end
    end
  end
end
