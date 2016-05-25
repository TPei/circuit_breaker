require "spec"
require "../lib/circuit_state.cr"

describe "CircuitState" do
  describe "#trip" do
    it "transitions from :closed to :open" do
      cs = CircuitState.new
      cs.state.should eq :closed

      cs.trip
      cs.state.should eq :open
    end

    it "does not transition from :open" do
      cs = CircuitState.new
      cs.trip
    end
  end

  describe "#reset" do
    it "transitions from :open to :closed" do
      cs = CircuitState.new
      cs.state.should eq :closed

      cs.trip
      cs.reset
      cs.state.should eq :closed
    end

    it "does not transition from :closed" do
      cs = CircuitState.new
      cs.state.should eq :closed
    end
  end
end
