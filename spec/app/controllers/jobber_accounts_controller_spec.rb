# frozen_string_literal: true

require "rails_helper"

RSpec.describe(JobberAccountsController, type: :controller) do
  let(:jobber_account) { create(:jobber_account) }
  let(:result) { JSON.parse(response.body) }

  describe "#jobber_account_name" do
    before do
      allow(controller).to(receive(:jobber_account_id).and_return(jobber_account.jobber_id))
      get :jobber_account_name
    end

    it "should return 200 status code" do
      expect(response).to(have_http_status(200))
    end

    it "should return the account name" do
      expect(result["jobber_account_name"]).to(eq(jobber_account.name))
    end
  end
end
