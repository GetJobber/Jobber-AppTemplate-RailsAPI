# frozen_string_literal: true

require "rails_helper"

RSpec.describe("/heartbeat") do
  it "routes root to application#heartbeat" do
    aggregate_failures do
      expect(get("/heartbeat")).to(route_to("application#heartbeat"))
    end
  end
end
