require 'rspec/mocks/argument_list_matcher'

module EMDextras::Spec
  class Spy
    def initialize(options = {})
      @calls = []
      @return_value = options[:default_return]
    end

    def called?(method_name, *args)
      count_calls(method_name, *args) > 0
    end

    def received_n_calls!(number, method_name, *args)
      probe_event_machine check: (Proc.new do
        received_calls_number = count_calls(method_name, *args)
        unless (received_calls_number == number ) 
          raise ExpectationFailed, "Expected #{method_name} to have been called #{number} times with parameters [#{args.join(",")}] but only received #{received_calls_number} such calls (also received the following calls: #{@calls.inspect})"
        end
      end)
    end

    def received_call!(method_name, *args)
      received_n_calls!(1, method_name, *args)
    end

    def respond_to?(symbol)
      true
    end

    def method_missing(method_name, *args, &block)
      @calls << { :name => method_name, :args => args }
      @return_value
    end

    private

    def check_if_received_call(method_name, *args)
      unless self.called?(method_name, *args)
        raise ExpectationFailed, "Expected #{method_name} to have been called with parameters [#{args.join(",")}] but only received calls #{@calls.inspect}"
      end
    end

    def count_calls(method_name, *args)
      arg_list_matcher = RSpec::Mocks::ArgumentListMatcher.new(*args)

      found = @calls.select do |call| 
        call[:name] ==  method_name && arg_list_matcher.args_match?(*call[:args])
      end
      found.size
    end

  end

  class ExpectationFailed < Exception
  end

end
