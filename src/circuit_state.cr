class CircuitState
  getter :state

  OPEN = :open
  CLOSED = :closed
  HALF_OPEN = :half_open

  ALLOWED_TRANSITIONS = {
    CLOSED => [OPEN],
    OPEN => [HALF_OPEN],
    HALF_OPEN => [OPEN, CLOSED]
  }

  def initialize
    @state = CLOSED
  end

  def trip
    assert_transition OPEN
    @state = OPEN
  end

  def attempt_reset
    assert_transition HALF_OPEN
    @state = HALF_OPEN
  end

  def reset
    assert_transition CLOSED
    @state = CLOSED
  end

  private def assert_transition(new_state)
    unless ALLOWED_TRANSITIONS[@state].includes? new_state
      raise IllegalStateTransition.new("From #{@state} to #{new_state}")
    end
  end
end

class IllegalStateTransition < Exception
end
