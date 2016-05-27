require "./circuit_state"
require "./error_watcher"

class CircuitBreaker
  @error_threshold : Int32
  @duration : Int32
  @reclose_time : Time

  def initialize(threshold @error_threshold, timewindow timeframe, reenable_after @duration, handled_errors = [] of Exception, ignored_errors = [] of Exception)
    @state = CircuitState.new
    @reclose_time = Time.new
    @error_watcher = ErrorWatcher.new(Time::Span.new(0, 0, timeframe))

    # two-step initialization because of known crystal compiler bug
    @handled_errors = [] of Exception
    @handled_errors += handled_errors
    @ignored_errors = [] of Exception
    @ignored_errors += ignored_errors
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
      if monitor? exc
        handle_execution_error
      end
      raise exc
    end
    
    return return_value
  end

  # ---------------------------
  # private methods
  # ---------------------------
  private def monitor?(exception : Exception)
    exception_type = exception.class
    errors = @handled_errors.map(&.class)
    ignored = @ignored_errors.map(&.class)
    (errors.includes?(exception_type) || errors.empty?) && !ignored.includes?(exception_type)
  end

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
