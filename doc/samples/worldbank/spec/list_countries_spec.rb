require_relative './support/spec_helper'
require_relative '../list_countries'

describe ListCountries do
  it "should successfully request a list of countries" do
    EM.run do
      subject.todo('ignored input').should succeed_according_to(lambda {|request|
        request.response_header.status.should == 200
        request.last_effective_url.to_s.should include 'worldbank.org'
      })
    end
  end
end
