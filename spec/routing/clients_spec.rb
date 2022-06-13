# frozen_string_literal: true

require "rails_helper"

RSpec.describe("/clients") do
  it "routes to clients#index" do
    aggregate_failures do
      expect(get("/clients")).to(route_to("clients#index"))
    end
  end
end
