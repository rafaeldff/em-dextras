if defined?(RSpec)
  RSpec::Matchers.define :succeed_with do |expected|
    match_unless_raises Exception do |actual_deferred|
      resolved_value = nil
      actual_deferred.callback do |value|
        resolved_value = value
      end
      actual_deferred.errback do |error|
        if error.is_a? Exception
          raise error
        else
          raise "Callback error: #{error.inspect}"
        end
      end

      probe_event_machine :check => (lambda do |ignored|
        resolved_value.should == expected
      end), :timeout => 1
    end
  end

  RSpec::Matchers.define :succeed_according_to do |proc_expecting|
    match_unless_raises Exception do |actual_deferred|
      resolved_value = nil
      actual_deferred.callback do |value|
        resolved_value = value
      end
      actual_deferred.errback do |error|
        if error.is_a? Exception
          raise error
        else
          raise "Callback error: #{error.inspect}"
        end
      end

      probe_event_machine :check => (lambda do |ignored|
        proc_expecting.call(resolved_value)
      end), :timeout => 1
    end
  end

  RSpec::Matchers.define :be_successful do |expected|
    match_unless_raises Exception do |actual_deferred|
      done = false
      actual_deferred.callback do
        done = true
      end
      actual_deferred.errback do |error|
        if error.is_a? Exception
          raise error
        else
          raise "Callback error: #{error.inspect}"
        end
      end

      probe_event_machine :check => (lambda do |ignored|
        done
      end), :timeout => 1
    end
  end

  RSpec::Matchers.define :be_a_failure do |expected|
    match_unless_raises Exception do |actual_deferred|
      done = false
      actual_deferred.callback do
        raise "Expected error but was success"
      end
      actual_deferred.errback do |error|
        done = true
      end

      probe_event_machine :check => (lambda do |ignored|
        done
      end), :timeout => 1
    end
  end

  RSpec::Matchers.define :fail_with do |expected|
    match_unless_raises Exception do |actual_deferred|
      resolved_value = nil
      actual_deferred.errback do |value|
        resolved_value = value
      end
      actual_deferred.callback do |error|
        raise "Should have failed, but succedded with #{error}"
      end

      probe_event_machine :check => (lambda do |ignored|
        resolved_value.should == expected
      end), :timeout => 1
    end
  end
end
