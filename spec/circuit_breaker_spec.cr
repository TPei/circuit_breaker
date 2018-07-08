require "spec"
require "../src/circuit_breaker.cr"

describe "CircuitBreaker" do
  describe "#run" do
    it "returns original block value on success" do
      breaker = CircuitBreaker.new(threshold: 20, timewindow: 60, reenable_after: 2)

      breaker.run do
        2
      end.should eq 2
    end

    it "passes on any raised exceptions" do
      breaker = CircuitBreaker.new(threshold: 20, timewindow: 60, reenable_after: 2)

      expect_raises MyError do
        breaker.run do
          raise MyError.new
        end
      end
    end

    it "throws a CircuitOpenException if the circuit is open" do
      breaker = CircuitBreaker.new(threshold: 20, timewindow: 60, reenable_after: 2)

      expect_raises MyError do
        breaker.run do
          raise MyError.new
        end
      end

      expect_raises CircuitOpenException do
        breaker.run do
          2
        end
      end

      expect_raises CircuitOpenException do
        breaker.run do
          raise MyError.new
        end
      end
    end
  end

  describe "feature test" do
    it "reenables after a given timeframe" do
      breaker = CircuitBreaker.new(threshold: 20, timewindow: 60, reenable_after: 2)

      10.times do
        breaker.run do
          "swag"
        end.should eq "swag"
      end

      3.times do
        expect_raises ArgumentError do
          breaker.run do
            raise ArgumentError.new
          end
        end
      end

      7.times do
        expect_raises CircuitOpenException do
          breaker.run do
            "swag"
          end
        end
      end

      sleep 2

      breaker.run do
        "swag"
      end.should eq "swag"
    end

    it "goes directly back to open if the first execution after reopening fails" do
      breaker = CircuitBreaker.new(threshold: 20, timewindow: 60, reenable_after: 2)

      10.times do
        breaker.run do
          "swag"
        end.should eq "swag"
      end

      3.times do
        expect_raises ArgumentError do
          breaker.run do
            raise ArgumentError.new
          end
        end
      end

      7.times do
        expect_raises CircuitOpenException do
          breaker.run do
            "swag"
          end
        end
      end

      sleep 2.1

      expect_raises ArgumentError do
        breaker.run do
          raise ArgumentError.new
        end
      end

      expect_raises CircuitOpenException do
        breaker.run do
          "swag"
        end
      end
    end

    it "errors and executions only count in a given timeframe" do
      breaker = CircuitBreaker.new(threshold: 20, timewindow: 2, reenable_after: 60)

      10.times do
        breaker.run do
          "swag"
        end.should eq "swag"
      end
      2.times do
        expect_raises ArgumentError do
          breaker.run do
            raise ArgumentError.new
          end
        end
      end

      sleep 3

      4.times do
        breaker.run do
          "swag"
        end.should eq "swag"
      end

      expect_raises ArgumentError do
        breaker.run do
          raise ArgumentError.new
        end
      end
    end

    it "if the breaker was given an array of Exception types, only those will be monitored" do
      breaker = CircuitBreaker.new(threshold: 20, timewindow: 2, reenable_after: 60, handled_errors: [MyError.new])

      10.times do
        expect_raises ArgumentError do
          breaker.run do
            raise ArgumentError.new
          end
        end
      end

      3.times do
        expect_raises MyError do
          breaker.run do
            raise MyError.new
          end
        end
      end

      expect_raises CircuitOpenException do
        breaker.run do
          raise MyError.new
        end
      end
    end

    it "if the breaker was given an array of Exception types to ignore, those will not be monitored" do
      breaker = CircuitBreaker.new(threshold: 20, timewindow: 2, reenable_after: 60, ignored_errors: [ArgumentError.new])

      10.times do
        expect_raises ArgumentError do
          breaker.run do
            raise ArgumentError.new
          end
        end
      end

      3.times do
        expect_raises MyError do
          breaker.run do
            raise MyError.new
          end
        end
      end

      expect_raises CircuitOpenException do
        breaker.run do
          raise MyError.new
        end
      end
    end
  end
end

class MyError < Exception
end
