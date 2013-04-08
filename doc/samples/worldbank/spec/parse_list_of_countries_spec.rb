require_relative './support/spec_helper'
require_relative '../parse_list_of_countries'

describe ParseListOfCountries do
  it "should return the second json array element" do
    http_request = stub(:response => %Q|[{"first":"el"},["second","el"]]|)
    subject.invoke(http_request).should == ["second","el"]
  end
end
