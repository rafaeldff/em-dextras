require_relative './support/spec_helper'
require_relative '../parse_worldbank_document'

describe ParseWorldbankDocument do
  it "should return the second json array element" do
    http_request = stub(:response => %Q|[{"first":"el"},["second","el"]]|)
    subject.invoke(http_request).should == ["second","el"]
  end

  it "should only take the first 10 elements" do
    http_request = stub(
      :response => %Q|[{"first":"el"},[#{'"a",'*11}"a"]]|)
    subject.invoke(http_request).should == Array.new(10, "a")
  end

  context "corner cases" do
    it "should return an empty array if there is no second element" do
      http_request = stub(:response => %Q|[{"first":"el"}]|)
      subject.invoke(http_request).should == []
    end

    it "should return an empty array if the second element is empty" do
      http_request = stub(:response => %Q|[{"first":"el"},[]]|)
      subject.invoke(http_request).should == []
    end
  end
end
