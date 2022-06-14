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

      it "should update the tokens of the existing jobber_account" do
        expect(JobberAccount.count).to(eq(1))
        expect(result_account.jobber_id).to(eq(account_id))
        expect(result_account.name).to(eq(account_name))
        expect(result_account.jobber_access_token).to(eq(tokens[:access_token]))
        expect(result_account.jobber_access_token_expired_by.utc.to_s).to(eq(tokens[:expires_at].utc.to_s))
        expect(result_account.jobber_refresh_token).to(eq(tokens[:refresh_token]))
      end

      it "should set jobber_account_id cookie" do
        expect(response.cookies["jobber_account_id"]).to(eq(account_id))
      end
    end

    context "when it is a new account" do
      let(:account_id) { "1234" }
      let(:account_name) { "New account name" }

      it { expect(response).to(have_http_status(:ok)) }

      it "should create a new jobber_account and set the tokens" do
        expect(JobberAccount.count).to(eq(2))
        expect(result_account.jobber_id).to(eq(account_id))
        expect(result_account.name).to(eq(account_name))
        expect(result_account.jobber_access_token).to(eq(tokens[:access_token]))
        expect(result_account.jobber_access_token_expired_by.utc.to_s).to(eq(tokens[:expires_at].utc.to_s))
        expect(result_account.jobber_refresh_token).to(eq(tokens[:refresh_token]))
      end

      it "should set jobber_account_id cookie" do
        expect(response.cookies["jobber_account_id"]).to(eq(account_id))
      end
    end
  end

  describe "#logout" do
    before { get :logout }

    it "should clear jobber_account_id cookie" do
      expect(response.cookies["jobber_account_id"]).to(be_nil)
    end
  end

  describe "#validade_user_session" do
    let(:result) { described_class.new.send(:validate_user_session) }

    context "when there is no cookie" do
      before do
        allow_any_instance_of(AuthController).to(receive(:jobber_account_id).and_return(nil))
        allow_any_instance_of(AuthController).to(receive(:render).and_return("Unauthorized"))
      end

      it "It should return Unauthorized" do
        expect(result).to(eq("Unauthorized"))
      end
    end

    context "when cookie is invalid" do
      before do
        allow_any_instance_of(AuthController).to(receive(:jobber_account_id).and_return("1234"))
        allow_any_instance_of(AuthController).to(receive(:render).and_return("Unauthorized"))
      end

      it "It should return Unauthorized" do
        expect(result).to(eq("Unauthorized"))
      end
    end

    context "when cookie is a valid jobber_id" do
      before do
        allow_any_instance_of(AuthController).to(receive(:jobber_account_id).and_return(jobber_account.jobber_id))
      end

      context "when access token is valid" do
        it "Should not call jobber_account refresh_jobber_access_token! method" do
          expect_any_instance_of(JobberAccount).to_not(receive(:refresh_jobber_access_token!))
          result
        end
      end

      context "when access token is expired" do
        before do
          allow_any_instance_of(JobberAccount).to(receive(:refresh_jobber_access_token!))

          jobber_account.jobber_access_token_expired_by = Time.now - 10.minutes
          jobber_account.save!
        end

        it "Should call jobber_account refresh_jobber_access_token! method" do
          expect_any_instance_of(JobberAccount).to(receive(:refresh_jobber_access_token!))
          result
        end
      end
    end
  end
end
