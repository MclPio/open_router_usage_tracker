require_relative "lib/open_router_usage_tracker/version"

Gem::Specification.new do |spec|
  spec.name        = "open_router_usage_tracker"
  spec.version     = OpenRouterUsageTracker::VERSION
  spec.authors     = [ "MclPio" ]
  spec.email       = [ "mclpious@gmail.com" ]
  spec.homepage    = "https://github.com/MclPio/open_router_usage_tracker"
  spec.summary     = "Track API token usage and cost from multiple LLM providers like OpenRouter, OpenAI, Google, and more."
  spec.description = "A simple Rails engine to log API usage from multiple LLM providers and provide methods for tracking user consumption over time, enabling easy rate-limiting."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.2"
end
