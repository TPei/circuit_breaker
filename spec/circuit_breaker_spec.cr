require "spec"
require "../src/circuit_breaker.cr"

describe "CircuitBreaker" do
  describe "feature test" do
    it "reenables after a given timeframe" do
      breaker = CircuitBreaker.new(threshold: 20, timewindow: 60, reenable_after: 2)

      (1..20).each do |n|
        if n <= 10
          breaker.run do
            "swag"
          end.should eq "swag"
        elsif n > 10 && n < 14
          expect_raises ArgumentError do
            breaker.run do
              raise ArgumentError.new
            end
          end
        else
          expect_raises CircuitOpenException do
            breaker.run do
              "swag"
            end
          end
        end
      end

      sleep 2

      breaker.run do
        "swag"
      end.should eq "swag"
    end

    it "errors and executions only count in a given timeframe" do
      breaker = CircuitBreaker.new(threshold: 20, timewindow: 2, reenable_after: 60)

      (1..12).each do |n|
        if n <= 10
          breaker.run do
            "swag"
          end.should eq "swag"
        else
          expect_raises ArgumentError do
            breaker.run do
              raise ArgumentError.new
            end
          end
        end
      end

      sleep 3

      (1..5).each do |n|
        if n <= 4
          breaker.run do
            "swag"
          end.should eq "swag"
        else
          expect_raises ArgumentError do
            breaker.run do
              raise ArgumentError.new
            end
          end
        end
      end
    end

    it "if the breaker was given an array of Exception types, only those will be monitored" do
      breaker = CircuitBreaker.new(threshold: 20, timewindow: 2, reenable_after: 60, handled_errors: [MyError.new])

      (1..10).each do |n|
        expect_raises ArgumentError do
          breaker.run do
            raise ArgumentError.new
          end
        end
      end

      (1..3).each do |n|
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
