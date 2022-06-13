# frozen_string_literal: true

require "rails_helper"

RSpec.describe("/jobber_account routes") do
  it "routes to reports#index" do
    aggregate_failures do
      expect(get("/jobber_account_name")).to(route_to("jobber_accounts#jobber_account_name"))
    end
  end
end
