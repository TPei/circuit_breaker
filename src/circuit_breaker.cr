require "./circuit_state"
require "./error_watcher"

class CircuitBreaker
  @threshold : Int32
  @duration : Int32
  @reclose_time : Time
  @timeframe : Time::Span

  def initialize(threshold error_threshold, timewindow timeframe, reenable_after duration)
    @threshold = error_threshold
    @duration = duration
    @state = CircuitState.new
    @reclose_time = Time.new
    @timeframe = Time::Span.new(0, 0, timeframe)
    @error_watcher = ErrorWatcher.new(@timeframe)
  end
  
  def run(&block)
    # if open and not reclosable -> fail
    if open?
      raise CircuitOpenException.new("Circuit Breaker Open")
    end

    # now state is closed and not reclosable

    # if error_rate still ok, execute
    if errors_ok?
      begin
        @error_watcher.add_execution

        return_value = yield
      rescue exc
        @error_watcher.add_failure
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

  # ---------------------------
  # private methods
  # ---------------------------
  private def open?
    @state.state == :open && !reclose?
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

  private def errors_ok?
    @error_watcher.error_rate < @threshold
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
