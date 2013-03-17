
# Receives two blocks as options: :action and :check.
# The :action block should trigger an asynchronous operation, or in other words,
# it should take a callback block as a parameter.
# If the :action block is not given, a default action
# is provided, that simply schedules the callback to
# be run on the next tick of the event machine.
#
# The :check block should verify some desired property (it should indicate
# a failed verification by throwing an exception). The :check block will be
# called from the callback given to :action. One way to think about it is that
# the :check block is what you'd directly pass as a callback to the action block
# were it not for the need to probe periodically.
#
# If the verification done by the :check block succeeds, this method will stop
# EventMachine and return normally. If the verification fails, it will retry after
# an interval (configurable via the :interval option). This will happen until
# a timeout expires (configurable via the :timeout option, in seconds), in
# which case the method will raise the verification exception
def probe_event_machine(options)
  action = options[:action] || forwarding_action
  check = options[:check]
  timeout = options[:timeout] || 5
  interval = options[:interval] || 0.2
  debug = !!options[:debug]

  probe_start_time = Time.new

  exceptions = []
  code = Proc.new do |arguments|
    begin
      puts "call to check" if debug
      check.call(arguments)
      puts "check succeeded, will stop event loop" if debug
      EM.stop_event_loop
    rescue Exception => exception
      puts "check failed" if debug
      exceptions << exception
      if (Time.now - probe_start_time) < timeout
        puts "will retry action after #{interval} seconds" if debug
        EM.add_timer(interval) do
          puts "retrying action" if debug
          action.call(code)
        end
      else
        puts "timeout exceeded. stop trying" if debug
        EM.stop_event_loop
        raise MultipleExceptions, "Exceptions while probing:\n\t#{exceptions.map(&:message).uniq.join(";\nand exception:\t")}"
      end
    end
  end

  puts "initial call to action" if debug
  action.call(code)
end


class MultipleExceptions < RuntimeError
end

def forwarding_action
  return Proc.new {|callback|
    EM.next_tick Proc.new { callback.call([])}
  }
end 

