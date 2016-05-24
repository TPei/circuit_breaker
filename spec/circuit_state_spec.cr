require "spec"
require "../lib/circuit_state.cr"

describe "CircuitState" do
  describe "#trip" do
    it "transitions from :closed, :half_open to :open" do
      cs = CircuitState.new
      cs.state.should eq :closed

      cs.trip
      cs.state.should eq :open

      cs.atempt_reset
      cs.state.should eq :half_open

      cs.trip
      cs.state.should eq :open
    end

    it "does not transition from :open" do
      cs = CircuitState.new
      cs.trip

      expect_raises Exception do
        cs.trip
      end
    end
  end

  describe "#atempt_reset" do
    it "transitions from :open to :half_open" do
      cs = CircuitState.new
      cs.state.should eq :closed

      cs.trip
      cs.atempt_reset
      cs.state.should eq :half_open
    end

    it "does not transition from :half_open or :closed" do
      cs = CircuitState.new
      cs.state.should eq :closed

      expect_raises Exception do
        cs.atempt_reset
      end

      cs.trip
      cs.atempt_reset
      cs.state.should eq :half_open
      
      expect_raises Exception do
        cs.atempt_reset
      end
    end
  end

  describe "#reset" do
    it "transitions from :open and :half_open to :closed" do
      cs = CircuitState.new
      cs.state.should eq :closed

      cs.trip
      cs.atempt_reset
      cs.state.should eq :half_open
      cs.reset
      cs.state.should eq :closed

      cs.trip
      cs.reset
      cs.state.should eq :closed
    end

    it "does not transition from :closed" do
      cs = CircuitState.new
      cs.state.should eq :closed

      expect_raises Exception do
        cs.reset
      end
    end
  end

  describe "#validate_state" do
    it "throws an error if state is not in given states" do
      cs = CircuitState.new
      cs.validate_state([:open, :closed]).should eq nil
      
      expect_raises Exception do
        cs.validate_state([:open])
      end
    end
  end
end
