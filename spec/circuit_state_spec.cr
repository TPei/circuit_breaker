require "spec"
require "../src/circuit_state.cr"

describe "CircuitState" do
  describe "#trip" do
    it "transitions from :closed to :open" do
      cs = CircuitState.new
      cs.state.should eq :closed

      cs.trip
      cs.state.should eq :open
    end
  end

  describe "#attempt_reset" do
    it "transitions from :open to :half_open" do
      cs = CircuitState.new
      cs.trip
      cs.attempt_reset
      cs.state.should eq :half_open
    end
  end

  describe "#reset" do
    it "transitions from :half_open to :closed" do
      cs = CircuitState.new
      cs.state.should eq :closed

      cs.trip
      cs.attempt_reset
      cs.reset
      cs.state.should eq :closed
    end

    it "does not transition from :closed" do
      cs = CircuitState.new
      cs.state.should eq :closed

      expect_raises IllegalStateTransition do
        cs.reset
      end
    end
  end
end
