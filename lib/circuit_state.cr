class CircuitState
  getter :state

  OPEN = :open
  CLOSED = :closed

  def initialize
    @state = CLOSED
  end

  def trip
    @state = OPEN
  end


  def reset
    @state = CLOSED
  end

  def validate_state(required_state)
    unless @state == required_state
      raise "illegal state transition"
    end
  end
end
