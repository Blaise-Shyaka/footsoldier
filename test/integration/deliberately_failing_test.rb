require "test_helper"

# Throwaway: shows that a failing test turns CI red (#119). This branch is never merged.
class DeliberatelyFailingTest < ActiveSupport::TestCase
  test "fails on purpose" do
    flunk "Deliberate failure: CI should report this pull request as red"
  end
end
