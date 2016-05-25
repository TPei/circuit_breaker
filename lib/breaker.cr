class Breaker
  getter :fail_count, :exec_count, :last_fail

  @threshold : Int32
  @duration : Int32
  @reclose_time : Time
  @last_fail : Time | Nil

  def initialize(threshold error_threshold, reenable_after duration)
    @threshold = error_threshold
    @duration = duration
    @state = CircuitState.new
    @fail_count = 0
    @exec_count = 0
    @last_fail = nil
    @reclose_time = Time.new
  end
  
  def increment_failure_count
    @fail_count += 1
    @last_fail = Time.new
  end

  def reset_failure_count
    @fail_count = 0
  end

  def trip
    @state.trip 

    @reclose_time = Time.new + Time::Span.new(0, 0, @duration)
  end

  def reset
    @state.reset

    @reclose_time = Time.new
    @fail_count = 0
    @exec_count = 0
  end

  def run(&block)
    # if open and not reclosable -> fail
    if @state.state == :open && !reclose?
      raise "CircuitOpenException"
    end

    # now state is closed and not reclosable

    # if error_rate still ok, execute
    if errors_ok?
      begin
        @exec_count += 1
        return_value = yield
      rescue
        @fail_count += 1
        @last_fail = Time.new
        if !errors_ok?
          open_circuit
        end
      end
    else # if error_rate not ok, open circuit
      open_circuit
      raise "CircuitExecption"
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

  def error_rate
    return 0 if @exec_count == 0

    @fail_count / @exec_count.to_f * 100
  end

  def open_circuit
    @state.trip
    @reclose_time = Time.new + Time::Span.new(0, 0, @duration)
  end
end
