class Breaker
  getter :fail_count, :last_fail

  @threshold : Int32
  @duration : Int32
  @reclose_time : Time
  @last_fail : Time | Nil

  def initialize(threshold error_threshold, reenable_after duration)
    @threshold = error_threshold
    @duration = duration
    @state = CircuitState.new
    @fail_count = 0
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

    # TODO: add
    # @reclose_time = Time.new + deactivate_time
  end

  def reset
    @state.reset

    @reclose_time = Time.new
  end

  def run(&block)
    if @state.state == :closed
      if errors_ok?
        yield
      end
    elsif reclose?
      yield
    end
  end

  def errors_ok?
    # TODO: check error rate
    true
  end

  def reclose?
    if Time.new > @reclose_time
      reset
      true
    else
      false
    end
  end
end
