class ParseListOfCountries
  include EMDextras::Chains::SynchronousStage
  def invoke(http)
    document_body = http.response
    json = JSON.parse document_body
    json[1]
  end
end
