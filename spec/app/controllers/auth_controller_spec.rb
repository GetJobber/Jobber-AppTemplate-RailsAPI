# frozen_string_literal: true

require "rails_helper"

RSpec.describe(AuthController, type: :controller) do
  let!(:jobber_account) { create(:jobber_account) }
  let(:result) { JSON.parse(response.body) }

  describe "#request_oauth2_access_token" do
    let(:tokens) do
      {
        access_token: "test access token",
        expires_at: Time.now + 30.minutes,
        refresh_token: "test refresh token",
      }
    end
    let(:account_id) { jobber_account.jobber_id }
    let(:account_name) { jobber_account.name }
    let(:account_data) do
      {
        "data" => {
          "account" => {
            "id" => account_id,
            "name" => account_name,
          },
        },
      }
    end
    let(:result_account) { JobberAccount.find_by(jobber_id: account_id) }

    before do
      allow_any_instance_of(JobberService).to(receive(:create_oauth2_access_token).and_return(tokens))
      allow_any_instance_of(JobberService).to(receive(:execute_query).and_return(account_data))

      post :request_oauth2_access_token
    end

    context "when account already exists" do
      it { expect(response).to(have_http_status(:ok)) }

      it "updates the tokens of the existing jobber_account" do
        expect(JobberAccount.count).to(eq(1))
        expect(result_account.jobber_id).to(eq(account_id))
        expect(result_account.name).to(eq(account_name))
        expect(result_account.jobber_access_token).to(eq(tokens[:access_token]))
        expect(result_account.jobber_access_token_expired_by.utc.to_s).to(eq(tokens[:expires_at].utc.to_s))
        expect(result_account.jobber_refresh_token).to(eq(tokens[:refresh_token]))
      end

      it "creates a session" do
        expect(session["account_id"]).not_to(be_nil)
        expect(session["account_id"]).to(eq(account_id))
      end
    end

    context "when it is a new account" do
      let(:account_id) { "1234" }
      let(:account_name) { "New account name" }

      it { expect(response).to(have_http_status(:ok)) }

      it "creates a new jobber_account and set the tokens" do
        expect(JobberAccount.count).to(eq(2))
        expect(result_account.jobber_id).to(eq(account_id))
        expect(result_account.name).to(eq(account_name))
        expect(result_account.jobber_access_token).to(eq(tokens[:access_token]))
        expect(result_account.jobber_access_token_expired_by.utc.to_s).to(eq(tokens[:expires_at].utc.to_s))
        expect(result_account.jobber_refresh_token).to(eq(tokens[:refresh_token]))
      end

      it "sets account_id session" do
        expect(session["account_id"]).not_to(be_nil)
        expect(session["account_id"]).to(eq(account_id))
      end
    end
  end

  describe "#logout" do
    before { get :logout }

    it "clears account_id session" do
      expect(session["account_id"]).to(be_nil)
      expect(response).to(have_http_status(:ok))
    end
  end
end
