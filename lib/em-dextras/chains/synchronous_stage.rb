module EMDextras::Chains::SynchronousStage
  def invoke(input)
    raise NotImplementedError.new("You must implement #invoke.")
  end

  def todo(input)
    begin 
      value = invoke(input)
      EMDextras::Chains::Deferrables.succeeded value
    rescue  => exception
      EMDextras::Chains::Deferrables.failed exception
    end
  end
end
