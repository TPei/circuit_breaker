require "./circuit_state"
require "./error_watcher"

# Simple Implementation of the circuit breaker pattern in Crystal.
#
# Given a certain error threshold, timeframe and timeout window, a breaker can be used to monitor criticial command executions. Circuit breakers are usually used to prevent unnecessary requests if a server ressource et al becomes unavailable. This protects the server from additional load and allows it to recover and relieves the client from requests that are doomed to fail.
#
# Wrap API calls inside a breaker, if the error rate in a given time frame surpasses a certain threshold, all subsequent calls will fail for a given duration.
class CircuitBreaker
  @error_threshold : Int32
  @duration : Int32
  @reclose_time : Time

  # creates a CircuitBreaker instance with a specified error threshold, timeframe, breaker duration and optionally a number of ignored or handled errors
  #
  # ```
  # breaker = CircuitBreaker.new(
  #   threshold: 5, # % of errors before you want to trip the circuit
  #   timewindow: 60, # in s: anything older will be ignored in error_rate
  #   reenable_after: 300 # after x seconds, the breaker will allow executions again
  # )
  # ```
  def initialize(threshold @error_threshold, timewindow timeframe, reenable_after @duration, handled_errors = [] of Exception, ignored_errors = [] of Exception)
    @state = CircuitState.new
    @reclose_time = Time.local
    @error_watcher = ErrorWatcher.new(Time::Span.new(hours: 0, minutes: 0, seconds: timeframe))

    # two-step initialization because of known crystal compiler bug
    @handled_errors = [] of Exception
    @handled_errors += handled_errors
    @ignored_errors = [] of Exception
    @ignored_errors += ignored_errors
  end

  # get's passed a block to watch for errors
  # every error thrown inside your block counts towards the error rate
  # once the threshold is surpassed, it starts throwing `CircuitOpenException`s
  # you can catch these rrors and implement some fallback behaviour
  # ```
  # begin
  #   breaker.run do
  #     my_rest_call()
  #   end
  # rescue exc : CircuitOpenException
  #   log "happens to the best of us..."
  #   42
  # end
  # ```
  def run(&block)
    # if open and not reclosable -> fail
    if open?
      raise CircuitOpenException.new("Circuit Breaker Open")
    end

    begin
      @error_watcher.add_execution
      return_value = yield
      handle_execution_success
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
    if error_rate >= @error_threshold || @state.state == :half_open
      open_circuit
    end
  end

  private def handle_execution_success
    if @state.state == :half_open
      reset
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

    @reclose_time = Time.local + Time::Span.new(hours: 0, minutes: 0, seconds: @duration)
  end

  private def reset
    @state.reset

    @reclose_time = Time.local
    @error_watcher.reset
  end

  private def error_rate
    @error_watcher.error_rate
  end

  private def reclose?
    if Time.local > @reclose_time
      @state.attempt_reset
      true
    else
      false
    end
  end

  private def open_circuit
    @state.trip
    @reclose_time = Time.local + Time::Span.new(hours: 0, minutes: 0, seconds: @duration)
  end
end

class CircuitOpenException < Exception
end
