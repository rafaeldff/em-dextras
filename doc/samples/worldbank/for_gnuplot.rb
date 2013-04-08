class ForGnuplot
  include EMDextras::Chains::SynchronousStage
  def invoke(data_item)
    country_code = data_item["country"]["id"]
    date         = data_item["date"]
    value        = data_item["value"]
    "#{country_code}\t#{date}\t#{value}"
  end
end
