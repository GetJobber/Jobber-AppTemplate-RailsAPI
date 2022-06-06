# frozen_string_literal: true

require "rails_helper"

RSpec.describe(ApplicationController) do
  describe "#heartbeat", type: :controller do
    before { get :heartbeat }

    context "should return 200 status code" do
      it { expect(response).to(have_http_status(:ok)) }
    end
  end
end
