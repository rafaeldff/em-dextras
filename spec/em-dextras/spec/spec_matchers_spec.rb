require 'spec_helper'

describe 'Spec Matchers' do
  describe :succeed_with do
    it "should accept a successful deferrable with the given value" do
      EM.run do
        success = EMDextras::Chains::Deferrables.succeeded("ok")
        success.should succeed_with("ok")
      end
    end

    it "should accept a deferrable if it eventually succeeds" do
      EM.run do
        deferrable = EventMachine::DefaultDeferrable.new
        EM.next_tick do
          deferrable.succeed("ok")
        end
        deferrable.should succeed_with("ok")
      end
    end

    it "should reject a successful deferrable with a different value" do
      expect {EM.run do
        success = EMDextras::Chains::Deferrables.succeeded("not ok")
        success.should succeed_with("ok")
      end}.to raise_error
    end

    it "should reject a failed deferrable" do
      expect {EM.run do
        success = EMDextras::Chains::Deferrables.failed("any")
        success.should succeed_with("ok")
      end}.to raise_error
    end
  end
  
  describe :succeed_according_to do
    it "should accept if the block eventually yields without raising" do
      EM.run do
        deferrable = EventMachine::DefaultDeferrable.new
        EM.next_tick { deferrable.succeed("ok") }
        deferrable.should succeed_according_to(lambda do |value|
          value.should == "ok"
        end)
      end
    end

    it "should reject if the block never yields without raising while probing" do
      expect {EM.run do
        deferrable = EventMachine::DefaultDeferrable.new
        deferrable.should succeed_according_to(lambda do |value|
          value.should == "ok"
        end)
      end}.to raise_error
    end
  end
end
