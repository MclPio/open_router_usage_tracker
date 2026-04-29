module OpenRouterUsageTracker
  class Configuration
    attr_accessor :pricing, :raw_response_redactor

    def initialize
      @pricing = {}
      @raw_response_redactor = ->(response) { response }
    end

    def pricing_for(provider, model)
      provider_pricing = fetch_hash(pricing, provider)
      return unless provider_pricing

      fetch_hash(provider_pricing, model)
    end

    def redact_raw_response(response)
      raw_response_redactor.call(response)
    end

    private

    def fetch_hash(hash, key)
      return unless hash.respond_to?(:key?)

      hash[key.to_s] || hash[key.to_sym]
    end
  end
end
