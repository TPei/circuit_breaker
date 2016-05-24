class CircuitState
  getter :state

  OPEN = :open
  HALF_OPEN = :half_open
  CLOSED = :closed

  def initialize
    @state = CLOSED
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
  end

  def validate_state(states)
    unless states.includes?(@state)
      raise "illegal state transition"
    end
  end
end
