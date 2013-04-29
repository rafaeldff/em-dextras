require 'spec_helper'
require 'em-dextras/extension/object/deferrable'

describe "EventMachine::Deferrable extensions"  do
  context "when the deferrable is succeeded" do
    it 'returns a new one deferrable with a yielded value' do
      EM.run do
        deferrable = EventMachine::DefaultDeferrable.new

        result_deferrable = deferrable.map do |parameter|
          "transformed-#{parameter}"
        end

        deferrable.succeed('from-succeed')

        result_deferrable.should succeed_with('transformed-from-succeed')
      end
    end
  end

  context "when the deferrable fails" do
    it 'returns a new one failed deferrable' do
      EM.run do
        deferrable = EventMachine::DefaultDeferrable.new

        result_deferrable = deferrable.map do |parameter|
          "transformed-#{parameter}"
        end

        deferrable.fail('from-fail')

        result_deferrable.should fail_with('from-fail')
      end
    end
  end
end
