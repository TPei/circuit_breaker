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
    transition_to OPEN
  end

  def attempt_reset
    transition_to HALF_OPEN
  end

  def reset
    transition_to CLOSED
  end

  private def transition_to(new_state)
    unless ALLOWED_TRANSITIONS[@state].includes? new_state
      raise IllegalStateTransition.new("From #{@state} to #{new_state}")
    end
    @state = new_state
  end
end

class IllegalStateTransition < Exception
end
