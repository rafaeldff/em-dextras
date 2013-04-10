require 'spec_helper'

describe EMDextras::Chains do
  class EchoStage
    def todo(input)
      EMDextras::Chains::Deferrables.succeeded(input)
    end
  end

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
      EMDextras::Chains::Deferrables.failed input
    end
  end

  class InvalidStage
    def todo(input)
      "Not a deferrable object"
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

  context " - when all stages succeed -" do
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

    it "should return a deferrable with the result of the last step" do
      EM.run do
        result = EMDextras::Chains.pipe("ignored", monitoring, [
          ProduceStage.new("out")
        ])

        result.should succeed_with("out")
      end
    end
  end

  context " - when a stage fails - " do
    it "should fail the resulting deferrable" do
      EM.run do
        result = EMDextras::Chains.pipe("error", monitoring, [
          EchoStage.new,
          ErrorStage.new,
          ProduceStage.new(42)
        ])

        result.should fail_with("error")
      end
    end

    it "should not proceed with the chain" do
      EM.run do
        produced = []

        result = EMDextras::Chains.pipe("in", monitoring, [
          SpyStage.new(produced),
          ErrorStage.new,
          SpyStage.new(produced)
        ])

        probe_event_machine check: (Proc.new do
          produced.should == ["in"]
        end)
      end
    end
  end

  context "- interruption -" do
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

    it "should notify the monitor that the chain ended (with nil value)" do
      EM.run do
        input = []

        monitoring = EMDextras::Spec::Spy.new

        EMDextras::Chains.pipe("input", monitoring, [
          ProduceStage.new("x"),
          InterruptChainStage.new,
          SpyStage.new(input)
        ])

        monitoring.received_call!(:end_of_chain!, nil)
      end
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
          ProduceStage.new("z")
        ])

        monitoring.received_call!(:end_of_chain!, "z")
      end
    end

    it "should notify monitoring of the end of the pipeline even when a stage fails" do
      EM.run do
        monitoring = EMDextras::Spec::Spy.new

        EMDextras::Chains.pipe("x", monitoring, [
          ProduceStage.new("y"),
          ErrorStage.new,
          ProduceStage.new("z")
        ])

        monitoring.received_call!(:end_of_chain!, "y")
      end
    end

    context 'when monitoring does not respond to end_of_chain' do
      it 'does not to try to call that method' do
        EM.run do
          monitoring = EMDextras::Spec::Spy.new only_respond_to: [:this_method]

          EMDextras::Chains.pipe('x', monitoring, [
            ProduceStage.new('y'),
            SpyStage.new([]),
            ProduceStage.new('z')
          ])

          monitoring.not_received_call!(:end_of_chain!, 'z')
        end
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
      
      it "should return a deferrable acccumulating the results of the last step" do
        EM.run do
          result = EMDextras::Chains.pipe("anything", monitoring, [
            ProduceStage.new([1,2]),
            :split,
            SpyStage.new([])
          ])

          result.should succeed_with([1,2])
        end
      end

      it "should return a deferrable with the result of the last step, accumulating results for multiple splits" do
        EM.run do
          result = EMDextras::Chains.pipe("anything", monitoring, [
            ProduceStage.new([1,2]),
            :split,
            ProduceStage.new([3,4]),
            :split,
            SpyStage.new([])
          ])

          result.should succeed_with([[3,4],[3,4]])
        end
      end

      it "should handle a split as first chain element" do
        EM.run do
          results = []
          EMDextras::Chains.pipe([1,2,3], monitoring, [
            :split,
            SpyStage.new(results)
          ])
          probe_event_machine :check => (lambda {|x|
            results.should == [1,2,3]
          })
        end
      end

      it "should handle a split as last chain element" do
        EM.run do
          result = EMDextras::Chains.pipe('ignored', monitoring, [
            ProduceStage.new([1,2,3]),
            :split
          ])

          result.should succeed_with([1,2,3])
        end
      end

      context " - splits and monitoring - " do
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

  context " - input validation - " do
    it "should raise an exception when a stage doesn't return a deferrable" do
      expect {EM.run do
        EMDextras::Chains.pipe("the input", monitoring, [
          InvalidStage.new
        ])
      end}.to raise_error(EMDextras::Chains::InvalidStage, "Stage 'InvalidStage' did not return a deferrable object when given input 'the input'!")
    end
  end
end
