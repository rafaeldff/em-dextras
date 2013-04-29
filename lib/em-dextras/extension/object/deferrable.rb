module EventMachine
  module Deferrable
    def map
      deferrable_result = EventMachine::DefaultDeferrable.new

      self.callback do |original_value|
        deferrable_result.succeed yield(original_value)
      end

      self.errback do |original_value|
        deferrable_result.fail original_value
      end

      deferrable_result
    end
  end
end
