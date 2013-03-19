require File.expand_path('spec/spec_helper')

describe EMDextras::Pipelines::SynchronousStage do
  class PasstroughSynchronousStage
    include EMDextras::Pipelines::SynchronousStage
    def invoke(input)
      "Got #{input}"
    end
  end

  class FailingSynchronousStage
    include EMDextras::Pipelines::SynchronousStage
    def invoke(input_exception)
      raise input_exception
    end
  end

  context "success:" do 
    subject { PasstroughSynchronousStage.new }

    it "should pass the return value of the invoke method to the next stage" do
      EM.run do 
        deferred = subject.todo "the input"
        deferred.should succeed_with "Got the input"
      end
    end
  end

  context "failure:" do
    subject { FailingSynchronousStage.new }

    it "should return a failed deferred" do
      EM.run do
        exception = ArgumentError.new "an exception"
        deferred = subject.todo exception
        deferred.should fail_with exception
      end
    end
  end
end
