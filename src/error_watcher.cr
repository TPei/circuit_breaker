class ErrorWatcher
  @failures = [] of Time
  @executions = [] of Time
  @timeframe : Time::Span

  def initialize(@timeframe)
  end

  def add_failure
    @failures << Time.new
  end

  def add_execution
    @executions << Time.new
  end

  def reset
    @failures = [] of Time
    @executions = [] of Time
  end

  def error_rate : Float64
    clean_old_records

    raise MoreErrorsThanExecutionsException.new if failure_count > execution_count
    return 0.to_f if @executions.size == 0

    failure_count / execution_count.to_f * 100
  end

  # ---------------------------
  # private methods
  # ---------------------------
  private def clean_old_records
    clean_old @failures
    clean_old @executions
  end

  private def clean_old(arr : Array(Time))
    threshold = Time.new - @timeframe

    arr.reject! { |time| time < threshold }
  end

  private def failure_count
    @failures.size
  end

  private def execution_count
    @executions.size
  end

end

class MoreErrorsThanExecutionsException < Exception
end
