require_relative './support/spec_helper'
require_relative '../for_gnuplot'

describe ForGnuplot do
  let (:data_item) { 
    JSON.parse <<-EOS
      {
        "date": "2009",
        "decimal": "0",
        "value": "1621661507655.08",
        "country": {
          "value": "Brazil",
          "id": "BR"
        },
        "indicator": {
          "value": "GDP (current US$)",
          "id": "NY.GDP.MKTP.CD"
        }
      }
    EOS
  } 

  it "prints a line with the country, date and value" do
    subject.invoke(data_item).should == "BR\t2009\t1621661507655.08"
  end
end
