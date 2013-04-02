require 'spec_helper'

describe EMDextras::Chains do 
  class ProduceStage
    def initialize(result)
      @result = result
    end

    def todo(ignored_input)
      EMDextras::Chains::Deferrables.succeeded @result
    end
  end

  class SpyStage
    def initialize(inputs)
      @inputs = inputs
    end

    def todo(input)
      @inputs << input
      EMDextras::Chains::Deferrables.succeeded input
    end
  end

  class ErrorStage
    def todo(input)
      EMDextras::Chains::Deferrables.failed "Failed with #{input}"
    end
  end

  class StopStage
    def todo(input)
      EM.stop
      EMDextras::Chains::Deferrables.succeeded input
    end
  end

  class ContextualStage
    attr :context
    def todo(input, context)
      @context = context
      EMDextras::Chains::Deferrables.succeeded input
    end
  end

  class InterruptChainStage
    def todo(ignored)
      deferrable = EventMachine::DefaultDeferrable.new
      deferrable.succeed()
      deferrable
    end
  end

  let(:monitoring) { mock.as_null_object }
  
  it "should chain todo stages" do
    EM.run do 
      inputs = []

      EMDextras::Chains.pipe("input", monitoring, [
        SpyStage.new(inputs),
        SpyStage.new(inputs),
        StopStage.new
      ])

      inputs.should == ["input", "input"]
    end
  end

  it "should interrupt the chain when a stage returns an empty succeeded deferrable" do
    EM.run do
      input = []
      
      EMDextras::Chains.pipe("input", monitoring, [
        ProduceStage.new("x"),
        InterruptChainStage.new,
        SpyStage.new(input)
      ])

      probe_event_machine check: (Proc.new do
        input.should == []
      end)
    end
    
  end

  context "- monitoring -" do 
    it "should notify monitoring of any exceptions" do
      EM.run do
        monitoring.should_receive(:inform_exception!) do 
          EM.stop
        end

        EM.add_timer(2) do
          fail("timeout")
        end

        EMDextras::Chains.pipe("anything", monitoring, [ErrorStage.new]);
      end
    end

    it "should notify monitoring of the end of the pipeline" do
      EM.run do 
        monitoring = EMDextras::Spec::Spy.new
        EMDextras::Chains.pipe("x", monitoring, [
          ProduceStage.new("y"),
          SpyStage.new([]),
          ProduceStage.new("z"),
        ])

        monitoring.received_call!(:end_of_chain!, "z")
      end
    end
  end

  context " - context - " do
    it "should pass a 'context' object if given and the stage takes one" do
      contextual_stage = ContextualStage.new

      EM.run do 
        EMDextras::Chains.pipe("anything", monitoring, [
          contextual_stage,
          StopStage.new
        ], :context => "the context")

        probe_event_machine :check => lambda {|x|
          contextual_stage.context.should == "the context"
        }
      end
    end

    it "should pass the contect object to monitoring if given" do
      EM.run do 
        monitoring = EMDextras::Spec::Spy.new
        EMDextras::Chains.pipe("x", monitoring, [
          ProduceStage.new("y"),
        ], context: "the context")

        monitoring.received_call!(:end_of_chain!, "y", "the context")
      end
    end
  end

  context "when given a :split stage" do 
    context "and the input is enumberable" do
      it "should invoke the next step the given number of times" do
        EM.run do
          final_inputs = []

          EMDextras::Chains.pipe("anything", monitoring, [
            ProduceStage.new([1,2,3]),
            :split,
            SpyStage.new(final_inputs),
            StopStage.new
          ])

          final_inputs.should =~ [1,2,3]
        end
      end

      it "successive splits should recursively divide the pipeline" do
        EM.run do
          final_inputs = []
          intermediate_inputs = []

          EMDextras::Chains.pipe("anything", monitoring, [
            ProduceStage.new([1,2]),
            :split,
            SpyStage.new(intermediate_inputs),
            ProduceStage.new([3,4]),
            :split,
            SpyStage.new(final_inputs),
            StopStage.new
          ])

          intermediate_inputs.should =~ [1,2]
          final_inputs.should =~ [3,4,3,4]
        end
      end

      it "should split the given context" do
        before = ContextualStage.new
        after = ContextualStage.new

        first_context  = double("first context")
        second_context = double("second context")

        first_context.stub(:split).and_return second_context

        EM.run do 
          EMDextras::Chains.pipe("anything", monitoring, [
            before,
            ProduceStage.new([1,2]),
            :split,
            after
          ], :context => first_context)

          probe_event_machine :check => lambda {|x|
            before.context.should == first_context
            after.context.should == second_context
          }
        end
      end

      it "should inform monitoring that the pipeline ended only once" do
        EM.run do
          monitoring = EMDextras::Spec::Spy.new

          EMDextras::Chains.pipe("anything", monitoring, [
            ProduceStage.new([1,2]),
            :split,
            ProduceStage.new([3,4]),
            :split,
            SpyStage.new([])
          ])

          monitoring.received_n_calls!(1, :end_of_chain!, [[3,4],[3,4]])
        end
      end

      it "should inform monitoring that the pipeline ended with context if given" do
        EM.run do
          monitoring = EMDextras::Spec::Spy.new

          EMDextras::Chains.pipe("anything", monitoring, [
            ProduceStage.new([1,2]),
            :split,
            ProduceStage.new([3,4]),
            :split,
            SpyStage.new([])
          ], context: :the_context)

          monitoring.received_n_calls!(1, :end_of_chain!, [[3,4],[3,4]], :the_context)
        end
      end
    end

    context "and the input is not enumberable" do
      it "will terminate the chain and report the error as an exception" do
        EM.run do 
          monitoring.should_receive(:inform_exception!) do 
            EM.stop
          end

          EM.add_timer(2) do
            fail("timeout")
          end

          EMDextras::Chains.pipe("anything", monitoring, [
            ProduceStage.new(:not_enumberable_input),
            :split,
            SpyStage.new([]),
            StopStage.new
          ])
        end
      end
    end
  end
end
