require_relative './support/spec_helper'
require_relative '../fetch_indicator'

describe FetchIndicator do
  let(:country) {
    JSON.parse <<-EOS
    {
      "latitude": "-15.7801",
      "longitude": "-47.9292",
      "id": "BRA",
      "iso2Code": "BR",
      "name": "Brazil",
      "region": {
        "value": "Latin America & Caribbean (all income levels)",
        "id": "LCN"
      },
      "adminregion": {
        "value": "Latin America & Caribbean (developing only)",
        "id": "LAC"
      },
      "incomeLevel": {
        "value": "Upper middle income",
        "id": "UMC"
      },
      "lendingType": {
        "value": "IBRD",
        "id": "IBD"
      },
      "capitalCity": "Brasilia"
    }
    EOS
  }

  subject { described_class.new 'SI.DST.10TH.10' }

  it "should successfully request a data series for the given country" do
    EM.run do
      subject.todo(country).should succeed_according_to(lambda {|http|
        http.response.should include 'Brazil'
      })
    end
  end

  it "the indicator requested should be the one provided" do
    EM.run do
      fetch = FetchIndicator.new('NY.GDP.MKTP.CD') 
      fetch.todo(country).should succeed_according_to(lambda {|http|
        http.response.should include 'GDP'
      })
    end
  end
end
