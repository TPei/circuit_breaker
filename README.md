# circuit_breaker

Simple Implementation of the circuit breaker pattern in Crystal.

Given a certain error threshold, timeframe and timeout window, a certain breaker can be used to monitor criticial command executions. Circuit breakers are usually usually used to prevent unnecessary requests if a server ressource et al becomes unavailable.

Wrap API calls inside a breaker, if the error rate in a given time frame surpasses a certain threshold, all subsequent calls will fail for a given duration.

## Usage

Create a new breaker:
```
breaker = Breaker.new(
  threshold: 5, # % of errors before you want to trip the circuit
  timewindow: 60, # in s: anything older will be ignored in error_rate
  reenable_after: 60 # after x seconds, the breaker will allow executions again
)
```

Then wrap whatever you like:
```
breaker.run do
  my_rest_call()
end
```

The Breaker will open and throw an CircuitOpenException for all subsequent calls, once the threshold is reached. You can of course catch these exceptions and do whatever you want :D
```
begin
  breaker.run do
    my_rest_call()
  end
rescue exc : CircuitOpenException
  log "happens to the best of us..."
  42
end
```

## Thanks
Special thanks goes to Pedro Belo on whose ruby circuit breaker implementation this is loosely based. [CB2](https://github.com/pedro/cb2)
