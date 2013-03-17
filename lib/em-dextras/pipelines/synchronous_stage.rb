module EMDextras::Pipelines::SynchronousStage
  def invoke(input)
    raise NotImplementedError.new("You must implement #invoke.")
  end

  def todo(input)
    begin 
      value = invoke(input)
      EMDextras::Pipelines::Deferrables.succeeded value
    rescue  => exception
      EMDextras::Pipelines::Deferrables.failed exception
    end
  end
end
