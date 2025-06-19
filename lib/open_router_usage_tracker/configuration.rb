module OpenRouterUsageTracker
  class Configuration
    # The list of options users can change, with their defaults.
    attr_accessor :user_foreign_key

    def initialize
      @user_foreign_key = :user_id
    end
  end
end
