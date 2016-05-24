class CircuitState
  getter :fail_count, :last_fail, :state

  OPEN = :open
  HALF_OPEN = :half_open
  CLOSED = :closed

  def initialize
    @state = CLOSED
    @fail_count = 0
    @last_fail = nil
  end

  def increment_failure_count
    @fail_count += 1
    @last_fail = Time.new
  end

  def reset_failure_count
    @fail_count = 0
  end

  def trip
    validate_state([CLOSED, HALF_OPEN])

    @state = OPEN
  end

  def atempt_reset
    validate_state([OPEN])

    @state = HALF_OPEN
  end

  def reset
    validate_state([OPEN, HALF_OPEN])

    @state = CLOSED
    reset_failure_count
  end

  def validate_state(states)
    unless states.includes?(@state)
      raise "illegal state transition"
    end
  end
end
