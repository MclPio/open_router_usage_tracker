require "test_helper"

class ProviderRegistryTest < ActiveSupport::TestCase
  test ".supported_provider_names lists the configured providers" do
    assert_equal(
      [ "open_ai", "open_router", "google", "anthropic", "x_ai" ],
      OpenRouterUsageTracker::Providers.supported_provider_names
    )
  end

  test ".parser_for returns provider parser classes" do
    assert_equal OpenRouterUsageTracker::Providers::OpenAi::Parser,
                 OpenRouterUsageTracker::Providers.parser_for("open_ai")
    assert_equal OpenRouterUsageTracker::Providers::Google::Parser,
                 OpenRouterUsageTracker::Providers.parser_for("google")
  end

  test ".parser_for raises a clear error for unsupported providers" do
    error = assert_raises(ArgumentError) do
      OpenRouterUsageTracker::Providers.parser_for("mystery_ai")
    end

    assert_match "Unsupported provider: mystery_ai", error.message
    assert_match "open_router", error.message
  end
end
