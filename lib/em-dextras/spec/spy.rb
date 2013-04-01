module EMDextras::Spec
  class Spy
    def initialize(options = {})
      @calls = []
      @return_value = options[:default_return]
    end

    def called?(method_name, *args)
      @calls.include? :name => method_name, :args => args
    end

    def received_call!(method_name, *args)
      probe_event_machine check: (Proc.new do
        check_if_received_call(method_name, *args)
      end)
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

  end

  class ExpectationFailed < Exception
  end

end
