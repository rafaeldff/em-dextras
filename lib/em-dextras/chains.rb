module EMDextras
  module Chains
    module Deferrables
      def self.succeeded(*args)
        deferrable = EventMachine::DefaultDeferrable.new
        deferrable.succeed(*args)
        deferrable
      end
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
      return if stages.empty?

      stage, *rest = *stages

      puts "Running #{stage}(#{input})" if pipe_setup.options[:debug]

      if stage == :split
        split_chain(input, rest, pipe_setup)
        return
      end


      deferrable = call(stage, input, pipe_setup)
      deferrable.callback do |value|
        run_chain value, rest, pipe_setup
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

      new_pipe_setup =  PipeSetup.new(pipe_setup.monitoring, new_options)

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
      case todo_method.arity
      when 1
        stage.todo(input)
      when 2
        stage.todo(input, pipe_setup.options[:context])
      end
    end
  end
end
