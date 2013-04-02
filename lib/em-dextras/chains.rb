module EMDextras
  module Chains
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
        #puts "args #{args.inspect} arg #{arg.inspect} ctx #{context_array.inspect}"
        
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

    PipeSetup = Struct.new(:monitoring, :options) do
      def inform_exception!(error_value, stage)
        self.monitoring.inform_exception! error_value, stage
      end
    end

    def self.pipe(zero, monitoring, stages, options = {})
      run_chain zero, stages, PipeSetup.new(monitoring, options)
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
        run_chain value, rest, pipe_setup unless should_halt
      end
      deferrable.errback do |error_value|
        pipe_setup.inform_exception! error_value, stage
      end
    end

    private
    def self.split_chain input, rest, pipe_setup
      new_options = pipe_setup.options.clone

      context = new_options[:context]
      if context && context.respond_to?(:split)
        new_options[:context] = context.split 
      end

      join_monitor = JoinMonitor.new(input.size, pipe_setup.monitoring)
      new_pipe_setup = PipeSetup.new(join_monitor, new_options)

      unless input.respond_to? :each
        pipe_setup.inform_exception! ArgumentError.new(":split stage expects enumerable input. \"#{input}\" is not enumerable."), :split
        return
      end
      input.each do |value|
        run_chain value, rest, new_pipe_setup
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

      if context
        monitoring.end_of_chain!(value, context)
      else
        monitoring.end_of_chain!(value)
      end
    end
  end
end
