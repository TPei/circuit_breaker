require "spec"
require "../lib/breaker.cr"

describe "Breaker" do
  describe "#run" do
    breaker = Breaker.new(threshold: 5, reenable_after: 10)
    breaker.run do
      "swag"
    end.should eq "swag"
  end

  describe "#increment_failure_count" do
    it "increments the failure count" do
      cs = Breaker.new(threshold: 5, reenable_after: 10)
      cs.fail_count.should eq 0
      cs.increment_failure_count
      cs.fail_count.should eq 1
    end
  end

  describe "#reset_failure_count" do
    it "resets the failure_count back to 0" do
      cs = Breaker.new(threshold: 5, reenable_after: 10)
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
      breaker = Breaker.new(threshold: 5, reenable_after: 10)

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
end
