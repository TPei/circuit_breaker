# circuit_breaker [![Build Status](https://travis-ci.org/TPei/circuit_breaker.svg?branch=master)](https://travis-ci.org/TPei/circuit_breaker) [![Say Thanks!](https://img.shields.io/badge/say_thanks-:%29-blue.svg)](https://saythanks.io/to/TPei)

###### This project is being built weekly with the latest crystal version (works with v1.7.2 🎉)

Simple Implementation of the [circuit breaker pattern](http://martinfowler.com/bliki/CircuitBreaker.html) in Crystal.

## What??!?

> The basic idea behind the circuit breaker is very simple. You wrap a protected function call in a circuit breaker object, which monitors for failures. Once the failures reach a certain threshold, the circuit breaker trips, and all further calls to the circuit breaker return with an error, without the protected call being made at all. Usually you'll also want some kind of monitor alert if the circuit breaker trips. - Martin Fowler

Given a certain error threshold, timeframe and timeout window, a breaker can be used to monitor criticial command executions. Circuit breakers are usually used to prevent unnecessary requests if a server ressource et al becomes unavailable. This protects the server from additional load and allows it to recover and relieves the client from requests that are doomed to fail.

Wrap API calls inside a breaker, if the error rate in a given time frame surpasses a certain threshold, all subsequent calls will fail for a given duration.

## Installation

Add to your shard.yml

```yaml
dependencies:
  circuit_breaker:
    github: tpei/circuit_breaker
    branch: master
```

and then install the library into your project with

```bash
$ crystal deps
```

## Usage

Create a new breaker:
```crystal
require "circuit_breaker"

breaker = CircuitBreaker.new(
  threshold: 5, # % of errors before you want to trip the circuit
  timewindow: 60, # in s: anything older will be ignored in error_rate
  reenable_after: 300 # after x seconds, the breaker will allow executions again
)
```

Then wrap whatever you like:
```crystal
breaker.run do
  my_rest_call()
end
```

### Handling CircuitBreaker trips

The Breaker will open and throw an CircuitOpenException for all subsequent calls, once the threshold is reached. You can of course catch these exceptions and do whatever you want :D
```crystal
begin
  breaker.run do
    my_rest_call()
  end
rescue exc : CircuitOpenException
  log "happens to the best of us..."
  42
end
```

After the given reenable time, the circuit will transition to "half open". This will completely reset the circuit if the next execution succeeds, but reopen the circuit and reset the timer if the next execution fails.

### Handling only certain error types

If you are feeling really funky, you can also limit the exception classes to monitor. You might want to catch `RandomRestError`, but not `ArgumentError`, so do this:
```crystal
breaker = CircuitBreaker.new(
  threshold: 5,
  timewindow: 60,
  reenable_after: 300,
  handled_errors: [RandomRestError.new]
)

breaker.run
  raise ArgumentError.new("won't count towards the error rate")
end
```

### Ignoring certain error types

Conversely, you can also add custom errors to ignore and count all others:
```crystal
breaker = CircuitBreaker.new(
  threshold: 5,
  timewindow: 60,
  reenable_after: 300,
  ignored_errors: [ArgumentError.new]
)

breaker.run
  raise ArgumentError.new("won't count towards the error rate")
end
```

Unfortunately this both won't match against exception subclasses just yet, so at the moment you have to specify the exact class to monitor and can't just use `RestException` to match every subclass like `RestTimeoutException < RestException`...


## Thanks
Special thanks goes to Pedro Belo on whose ruby circuit breaker implementation ([CB2](https://github.com/pedro/cb2)) this is loosely based. 
