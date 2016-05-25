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
end
