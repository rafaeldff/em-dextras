class ParseWorldbankDocument
  include EMDextras::Chains::SynchronousStage
  def invoke(http)
    document_body = http.response
    json = JSON.parse document_body
    (json.size > 1 && json[1]) ? json[1].take(10) : []
  end
end
