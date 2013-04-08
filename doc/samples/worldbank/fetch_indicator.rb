class FetchIndicator
  def initialize(indicator)
    @indicator = indicator
  end

  def todo(country)
    id = country["id"]
    http = EventMachine::HttpRequest.new(indicator_url(id))
    http.get
  end

  private
  def indicator_url(country_id)
    "http://api.worldbank.org/countries/#{country_id}/indicators/#@indicator?format=json" 
  end
end
