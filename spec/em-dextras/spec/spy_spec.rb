require 'spec_helper'

describe EMDextras::Spec::Spy do
  subject { described_class.new }
  
  describe :"called?" do
    it "should record calls" do
      subject.foo(1, :a => "b")

      subject.called?(:foo, 1, :a => "b").should be_true
      subject.called?(:bar, 1, :a => "b").should be_false
      subject.called?(:foo, 1, :a => "c").should be_false
    end  
  end

  describe "default return value" do
    it "returns nil if no default return value is defined" do
      spy = EMDextras::Spec::Spy.new 
      spy.some_method.should == nil
    end

    it "returns the default value if defined" do
      spy = EMDextras::Spec::Spy.new :default_return => "default"
      spy.some_method.should == "default"
    end
  end

  describe :respond_to? do
    it "will always return true" do
      subject.respond_to?(:any_method_name).should be_true
    end
  end

  describe :received_call! do
    it "should do nothing if the call was really received" do
      EM.run do 
        subject.foo(1, :a => "b")

        subject.received_call!(:foo, 1, :a => "b")
      end
    end

    it "should raise an exception if the call was not received" do
      expect {
        EM.run do 
          subject.foo(1, :a => "b")
        
          subject.received_call!(:bar, 1, :a => "b")
        end
      }.to raise_error(/bar.*foo/)
    end

    it "should accept rspec argument matchers" do
      subject.foo(1, "banana")

      EM.run { subject.received_call!(:foo, 1, /ba(na)*/) } #doesn't raise
      expect {EM.run { subject.received_call!(:foo, 1, /apple/) } }.to raise_error
    end

    context "when the method is triggered asynchronously" do
      it "should should probe until the call is received" do
        EM.run do
          EM.next_tick do 
            subject.foo(1,2,3)
          end
  
          subject.received_call!(:foo, 1,2,3)
        end
      end
    end
  end

  describe :received_n_calls! do
    it "should do nothing if the call was received the given number of tiems" do
      EM.run do 
        subject.foo(42, :a => "b")
        subject.foo(42, :a => "b")

        subject.received_n_calls!(2, :foo, 42, :a => "b")
      end
    end

    it "should raise an exception if the call was not received" do
      expect {
        EM.run do 
          subject.received_n_calls!(1, :bar, :a => "b")
        end
      }.to raise_error(/1.*0/)
    end

    it "should raise an exception if the call was received a number of times less than what was expected" do
      expect {
        EM.run do 
          subject.foo(:a => "b")

          subject.received_n_calls!(2, :foo, :a => "b")
        end
      }.to raise_error(/2.*1/)
    end
    
  end

end
