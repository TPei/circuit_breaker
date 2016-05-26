class CircuitBreaker
  @threshold : Int32
  @duration : Int32
  @reclose_time : Time
  @timeframe : Int32

  def initialize(threshold error_threshold, timewindow timeframe, reenable_after duration)
    @threshold = error_threshold
    @duration = duration
    @state = CircuitState.new
    @reclose_time = Time.new
    @failures = [] of Time
    @executions = [] of Time
    @timeframe = timeframe
  end
  
  def increment_failure_count
    @failures << Time.new
  end

  def reset_failure_count
    @failures = [] of Time
  end

  def trip
    @state.trip 

    @reclose_time = Time.new + Time::Span.new(0, 0, @duration)
  end

  def reset
    @state.reset

    @reclose_time = Time.new
    @failures = [] of Time
    @executions = [] of Time
  end

  def run(&block)
    # if open and not reclosable -> fail
    if @state.state == :open && !reclose?
      raise CircuitOpenException.new("Circuit Breaker Open")
    end

    # now state is closed and not reclosable

    # if error_rate still ok, execute
    if errors_ok?
      begin
        @executions << Time.new

        return_value = yield
      rescue exc
        increment_failure_count
        if !errors_ok?
          open_circuit
        end
        raise exc
      end
    else # if error_rate not ok, open circuit
      open_circuit
      raise CircuitOpenException.new("Circuit Breaker Opened")
    end
    
    return return_value
  end

  def errors_ok?
    error_rate < @threshold
  end

  def reclose?
    if Time.new > @reclose_time
      reset
      true
    else
      false
    end
  end

  def error_rate : Float64
    clean_old @failures, "failures"
    clean_old @executions, "executions"

    return 0.to_f if @executions.empty?

    @failures.size / @executions.size.to_f * 100
  end

  def open_circuit
    @state.trip
    @reclose_time = Time.new + Time::Span.new(0, 0, @duration)
  end

  def clean_old(arr : Array(Time), name = "failures" )
    threshold = Time.new - Time::Span.new(0, 0, @timeframe) 

    arr.reject! { |time| time < threshold }
  end

  def fail_count
    @failures.size
  end

  def exec_count
    @executions.size
  end
end

class CircuitOpenException < Exception
end
