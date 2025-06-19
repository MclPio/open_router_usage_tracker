require_relative "lib/open_router_usage_tracker/version"

Gem::Specification.new do |spec|
  spec.name        = "open_router_usage_tracker"
  spec.version     = OpenRouterUsageTracker::VERSION
  spec.authors     = [ "MclPio" ]
  spec.email       = [ "mclpious@gmail.com" ]
  spec.homepage    = "https://github.com/MclPio/open_router_usage_tracker"
  spec.summary     = "Tracks yours AI token usage"
  spec.description = "This gem is your rocket launch to managing you web app's LLM usage and rate limiting users with built in methods!"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/MclPio/open_router_usage_tracker"
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.2"
end
