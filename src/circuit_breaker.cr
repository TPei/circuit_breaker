require "./circuit_state"
require "./error_watcher"

class CircuitBreaker
  @error_threshold : Int32
  @duration : Int32
  @reclose_time : Time

  def initialize(threshold @error_threshold, timewindow timeframe, reenable_after @duration)
    @state = CircuitState.new
    @reclose_time = Time.new
    @error_watcher = ErrorWatcher.new(Time::Span.new(0, 0, timeframe))
  end
  
  def run(&block)
    # if open and not reclosable -> fail
    if open?
      raise CircuitOpenException.new("Circuit Breaker Open")
    end

    begin
      @error_watcher.add_execution
      return_value = yield
    rescue exc
      handle_execution_error
      raise exc
    end
    
    return return_value
  end

  # ---------------------------
  # private methods
  # ---------------------------
  private def handle_execution_error
    @error_watcher.add_failure
    if error_rate >= @error_threshold
      open_circuit
    end
  end

  private def open?
    @state.state == :open && !reclose? && !openable?
  end

  private def openable?
    if error_rate >= @error_threshold && @state.state != :open
      open_circuit
      true
    else
      false
    end
  end

  private def trip
    @state.trip

    @reclose_time = Time.new + Time::Span.new(0, 0, @duration)
  end

  private def reset
    @state.reset

    @reclose_time = Time.new
    @error_watcher.reset
  end

  private def error_rate
    @error_watcher.error_rate
  end

  private def reclose?
    if Time.new > @reclose_time
      reset
      true
    else
      false
    end
  end

  private def open_circuit
    @state.trip
    @reclose_time = Time.new + Time::Span.new(0, 0, @duration)
  end
end

class CircuitOpenException < Exception
end
