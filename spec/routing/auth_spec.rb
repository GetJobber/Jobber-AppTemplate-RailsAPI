# frozen_string_literal: true

require "rails_helper"

RSpec.describe("/auth routes") do
  it "routes to auth#request_oauth2_access_token" do
    aggregate_failures do
      expect(post("/request_access_token")).to(route_to("auth#request_oauth2_access_token"))
    end
  end

  it "routes to auth#logout" do
    aggregate_failures do
      expect(get("/logout")).to(route_to("auth#logout"))
    end
  end
end
