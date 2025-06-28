class User < ApplicationRecord
  include OpenRouterUsageTracker::Trackable
end
