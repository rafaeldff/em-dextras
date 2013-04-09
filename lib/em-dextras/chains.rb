module EMDextras
  module Chains

    class JoinedDeferrable
      include EventMachine::Deferrable

      def initialize(deferrables)
        result_pairs = deferrables.map do |deferrable|
          [deferrable, :unset]
        end
        @results = Hash[result_pairs]
        @callback_values = []
        @errback_values = []

        initialize_deferrables!
      end

      def one_callback(*vs)
        deferrable, *values = vs
        @results[deferrable] = :ok
        @callback_values.push *values

        check_if_complete
      end

      def one_errback(*vs)
        deferrable, *values = vs
        @results[deferrable] = :error
          @errback_values.push *values

        check_if_complete
      end

      private

      def check_if_complete
        complete! unless any_was?(:unset)
      end

      def complete!
        (self.fail(@errback_values); return) if any_was?(:error)
        self.succeed(@callback_values)
      end

      def any_was?(state)
        @results.any? {|k, v| v == state }
      end

      def initialize_deferrables!
        ds = @results.keys

        ds.each do |deferrable|
          deferrable.callback do |*values|
            self.one_callback deferrable, *values
          end
          deferrable.errback do |*values|
            self.one_errback deferrable, *values
          end
        end

        ds.each do |d|
          d.timeout(5, "Expired timeout of #{5} for #{d.inspect}")
        end
      end
    end

    class JoinMonitor
      def initialize(size, underlying)
        @underlying = underlying
        @resolved = size
        @args = []
      end

      def inform_exception!(*args)
        @underlying.inform_exception!(*args)
      end

      def end_of_chain!(arg, context=nil)
        @args << arg
        @resolved -= 1
        complete!(@args, context) if @resolved == 0
      end

      def complete!(args, context)
        if context.nil?
          @underlying.end_of_chain! args
        else
          @underlying.end_of_chain! args, context
        end
      end
    end
    
    class JoinStage
      def initialize(size)
        @size = size
        @args = []
        @result = EventMachine::DefaultDeferrable.new
      end

      def todo(argument)
        @args << argument
        check_if_complete!
        @result
      end

      def result
        @result
      end

      private
      def check_if_complete!
        @result.succeed(@args) if @args.size == @size
      end
    end

    module Deferrables
      def self.succeeded(*args)
        deferrable = EventMachine::DefaultDeferrable.new
        deferrable.succeed(*args)
        deferrable end
      def self.failed(*args)
        deferrable = EventMachine::DefaultDeferrable.new
        deferrable.fail(*args)
        deferrable
      end
    end

    PipeSetup = Struct.new(:monitoring, :options, :result) do
      def inform_exception!(error_value, stage)
        self.monitoring.inform_exception! error_value, stage
      end
    end

    def self.pipe(zero, monitoring, stages, options = {})
      result = EventMachine::DefaultDeferrable.new
      run_chain zero, stages, PipeSetup.new(monitoring, options, result)
    end

    def self.run_chain input, stages, pipe_setup
      return chain_ended!(input, pipe_setup) if stages.empty?

      stage, *rest = *stages

      if stage == :split
        split_chain(input, rest, pipe_setup)
        return
      end

      deferrable = call(stage, input, pipe_setup)
      deferrable.callback do |value|
        should_halt = value.nil?
        if should_halt
          chain_ended!(value, pipe_setup)
        else
          run_chain value, rest, pipe_setup
        end
      end
      deferrable.errback do |error_value|
        pipe_setup.inform_exception! error_value, stage
      end

      pipe_setup.result
    end

    private
    def self.split_chain input, rest, pipe_setup
      new_options = pipe_setup.options.clone

      context = new_options[:context]
      if context && context.respond_to?(:split)
        new_options[:context] = context.split
      end

      join_monitor = JoinMonitor.new(input.size, pipe_setup.monitoring)
      rest_of_chain = rest

      unless input.respond_to? :each
        pipe_setup.inform_exception! ArgumentError.new(":split stage expects enumerable input. \"#{input}\" is not enumerable."), :split
        return
      end

      splits_deferrables = input.map do |value|
        split_result = EventMachine::DefaultDeferrable.new
        new_pipe_setup = PipeSetup.new(join_monitor, new_options, split_result)
        run_chain value, rest_of_chain, new_pipe_setup

        split_result
      end

      join = JoinedDeferrable.new(splits_deferrables)
      join.callback do |*values|
        pipe_setup.result.succeed(*values)
      end
      join.errback do |*values|
        pipe_setup.result.fail(*values)
      end
    end

    def self.call(stage, input, pipe_setup)
      todo_method = stage.method(:todo)
      arity = todo_method.arity
      if arity < 0 && pipe_setup.options[:context]
        stage.todo(input, pipe_setup.options[:context])
      elsif arity < 0 || arity == 1
        stage.todo(input)
      elsif arity == 2
        stage.todo(input, pipe_setup.options[:context])
      end
    end

    def self.chain_ended!(value, pipe_setup)
      context = pipe_setup.options[:context]
      monitoring = pipe_setup.monitoring

      if monitoring.respond_to? :end_of_chain!
        if context
          monitoring.end_of_chain!(value, context)
        else
          monitoring.end_of_chain!(value)
        end
      end

      pipe_setup.result.succeed(value)
    end
  end
end
