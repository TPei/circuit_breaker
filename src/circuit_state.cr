class CircuitState
  getter :state

  OPEN = :open
  CLOSED = :closed
  HALF_OPEN = :half_open

  def initialize
    @state = CLOSED
  end

  def trip
    @state = OPEN
  end

  def attempt_reset
    @state = HALF_OPEN
  end

  def reset
    @state = CLOSED
  end
end
