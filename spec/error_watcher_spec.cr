require "spec"
require "../src/error_watcher.cr"

describe "ErrorWatcher" do
  describe "#add_failure" do
    it "adds a failure timestamp to @failures array" do
    end
  end

  describe "#error_rate" do
    it "calculates error rate correctly and cleans after time" do
      watcher = ErrorWatcher.new(Time::Span.new(0, 0, 1))
      watcher.add_failure
      watcher.add_execution
      watcher.error_rate.should eq 100
      sleep 2
      watcher.error_rate.should eq 0
    end

    it "throws an error if there are more failures than executions" do
      watcher = ErrorWatcher.new(Time::Span.new(0, 0, 60))
      watcher.add_failure
      expect_raises MoreErrorsThanExecutionsException do
        watcher.error_rate
      end
    end

    it "returns 0 if failures and executions are empty" do
      watcher = ErrorWatcher.new(Time::Span.new(0, 0, 60))
      watcher.error_rate.should eq 0
    end
  end
end
