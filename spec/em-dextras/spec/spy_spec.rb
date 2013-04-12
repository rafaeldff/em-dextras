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
    context 'without respond parameter' do
      let(:spy) { described_class.new }

      it 'always returns true' do
        spy.respond_to?(:method_name).should be_true
      end
    end

    context 'with respond parameter on initialize' do
      let(:spy) { described_class.new only_respond_to: [:foo] }

      context 'and asking if it respond for the same method of initialize' do
        it 'returns true' do
          spy.respond_to?(:foo).should be_true
        end
      end

      context 'and asking if it respond for the a method different of the initialize' do
        it 'returns false' do
          spy.respond_to?(:bar).should be_false
        end
      end
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

    context " - rspec argument matchers - " do
      it "should accept rspec specific argument matchers"  do
        subject.foo(1, "banana")

        EM.run { subject.received_call!(:foo, 1, /ba(na)*/) } #doesn't raise
        EM.run { subject.received_call!(:foo, 1, instance_of(String)) } #doesn't raise
        expect {EM.run { subject.received_call!(:foo, 1, /apple/) } }.to raise_error
      end

      it "should accept rspec general matchers" do
        subject.foo(1, "banana")

        EM.run { subject.received_call!(:foo, any_args) } #doesn't raise
      end
    end

    it "should be able to assert that a method will receive nil" do
      EM.run do
        subject.foobar(nil)

        subject.received_call!(:foobar, nil)
      end
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

   describe :not_received_call! do
    it 'does not be called' do
      EM.run do
        subject.not_received_call!(:foo, a: 'b')
      end
    end

    it 'raises an exception if the call was received' do
      expect {
        EM.run do
          subject.foo(a: 'b')

          subject.not_received_call!(:foo, a: 'b')
        end
      }.to raise_error
    end
  end
end
