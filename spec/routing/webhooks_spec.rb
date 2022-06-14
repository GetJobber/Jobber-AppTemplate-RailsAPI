# frozen_string_literal: true

require "rails_helper"

RSpec.describe("/webhooks") do
  it "routes root to webhooks#index" do
    aggregate_failures do
      expect(post("/webhooks")).to(route_to(controller: "webhooks/webhook_receiver", action: "index"))
    end
  end
end
