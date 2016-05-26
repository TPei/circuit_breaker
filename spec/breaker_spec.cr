require "spec"
require "../src/breaker.cr"

describe "Breaker" do
  describe "feature test" do
    it "reenables after a given timeframe" do
      breaker = Breaker.new(threshold: 20, timewindow: 60, reenable_after: 2)

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
      breaker = Breaker.new(threshold: 20, timewindow: 2, reenable_after: 60)

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
  end

  describe "#run" do
    it "executes a given block and counts executions" do
      breaker = Breaker.new(threshold: 5, timewindow: 60, reenable_after: 10)
      breaker.run do
        "swag"
      end.should eq "swag"
      breaker.exec_count.should eq 1
      breaker.fail_count.should eq 0
    end

    it "counts fails for failing blocks and sets last_fail timestamp" do
      breaker = Breaker.new(threshold: 5, timewindow: 60, reenable_after: 10)
      expect_raises ArgumentError do
        breaker.run do
          raise ArgumentError.new
        end
      end
      breaker.exec_count.should eq 1
      breaker.fail_count.should eq 1
    end

    it "does not execute if error_rate is too high" do
      breaker = Breaker.new(threshold: 5, timewindow: 60, reenable_after: 10)
      expect_raises ArgumentError do
        breaker.run do
          raise ArgumentError.new
        end
      end
      breaker.exec_count.should eq 1
      breaker.fail_count.should eq 1

      # error rate too high now
      expect_raises CircuitOpenException do
        breaker.run do
          "swag"
        end
      end
    end

    it "allows for error catching" do
      breaker = Breaker.new(threshold: 5, timewindow: 60, reenable_after: 10)
      expect_raises ArgumentError do
        breaker.run do
          raise ArgumentError.new
        end
      end
      breaker.exec_count.should eq 1
      breaker.fail_count.should eq 1

      # error rate too high now
      begin
        breaker.run do
          "swag"
        end
      rescue ex : CircuitOpenException
        ex.class.should eq CircuitOpenException
        ex.message.should eq "Circuit Breaker Open"
      end
    end

    it "resets circuit after the given time" do
      breaker = Breaker.new(threshold: 5, timewindow: 60, reenable_after: 1)
      expect_raises ArgumentError do
        breaker.run do
          raise ArgumentError.new
        end
      end
      breaker.exec_count.should eq 1
      breaker.fail_count.should eq 1
      
      # error rate too high now
      expect_raises CircuitOpenException do
        breaker.run do
          "swag"
        end
      end

      breaker.exec_count.should eq 1
      breaker.fail_count.should eq 1

      sleep 2

      breaker.run do
        "swag"
      end.should eq "swag"
    end
  end

  describe "#increment_failure_count" do
    it "increments the failure count" do
      cs = Breaker.new(threshold: 5, timewindow: 60, reenable_after: 10)
      cs.fail_count.should eq 0
      cs.increment_failure_count
      cs.fail_count.should eq 1
    end
  end

  describe "#reset_failure_count" do
    it "resets the failure_count back to 0" do
      cs = Breaker.new(threshold: 5, timewindow: 60, reenable_after: 10)
      cs.fail_count.should eq 0
      cs.reset_failure_count
      cs.fail_count.should eq 0
      cs.increment_failure_count
      cs.increment_failure_count
      cs.fail_count.should eq 2
      cs.reset_failure_count
      cs.fail_count.should eq 0
    end
  end

  describe "#trip" do
    it "calls trip on state and sets a reclose_time" do
      breaker = Breaker.new(threshold: 5, timewindow: 60, reenable_after: 10)

      # can you mock/stub yet?
    end
  end

  describe "#errors_ok?" do
    it "calculates error rate and checks if it is acceptable" do
    end
  end

  describe "#reclose" do
    it "check if breaker can be reclosed again" do
    end
  end

  describe "#open_circuit" do
    it "opens the circuit and sets the appropriate reopen time" do
      breaker = Breaker.new(threshold: 10, timewindow: 60, reenable_after: 10)
      breaker.trip
    end
  end

  describe "#clean_old" do
    it "removes all entries older than set time" do
      breaker = Breaker.new(threshold: 10, timewindow: 1, reenable_after: 10)
      now = Time.new
      inside = now + Time::Span.new(0, 0, 2)
      old = [ now - Time::Span.new(0, 0, 1), now, now + Time::Span.new(0, 0, 1), inside]
      new = [ inside ]
      sleep 2
      breaker.clean_old(old)
      old.should eq new
    end
  end
end
