# frozen_string_literal: true

require "rails_helper"

RSpec.describe(JobberAccountsController, type: :controller) do
  let(:jobber_account) { create(:jobber_account) }
  let(:result) { JSON.parse(response.body) }

  before do
    allow(request).to(receive(:session).and_return({ account_id: jobber_account.jobber_id }))
  end

  describe "#jobber_account_name" do
    before { get :jobber_account_name }

    it "returns 200 status code" do
      expect(response).to(have_http_status(:ok))
    end

    it "returns the account name" do
      expect(result["accountName"]).to(eq(jobber_account.name))
    end
  end
end
