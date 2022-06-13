# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Webhooks::WebhookReceiverController, type: :controller) do
  describe "#incoming_webhook" do
    let(:data) { {} }
    let(:params) { { data: data } }

    context "when webhook receives an invalid hmac header" do
      it "should respond unauthorized" do
        post_headers = {
          "X-Jobber-Hmac-SHA256" => "Some random invalid hmac",
        }

        request.headers.merge!(post_headers)

        post :index, params: params, xhr: true

        expect(response).to(have_http_status(:unauthorized))
      end
    end

    context "when webhook receives no hmac header" do
      it "should respond unauthorized" do
        post :index, params: params, xhr: true

        expect(response).to(have_http_status(:unauthorized))
      end
    end

    context "when webhook receives a valid hmac header but invalid data" do
      it "should respond bad request" do
        allow(ActiveSupport::SecurityUtils).to(receive(:secure_compare).and_return(true))

        post :index, params: params, xhr: true

        expect(response).to(have_http_status(:bad_request))
      end
    end

    context "when webhook receives a bad topic" do
      let(:data) { { webHookEvent: { topic: "BAD_TOPIC" } } }

      it "should respond bad request" do
        allow(ActiveSupport::SecurityUtils).to(receive(:secure_compare).and_return(true))

        post :index, params: params, xhr: true

        expect(response).to(have_http_status(:bad_request))
      end
    end

    context "when webhook receives APP_DISCONNECT" do
      context "with an account id" do
        let!(:jobber_account) { create(:jobber_account, jobber_id: "test") }
        let(:jobber_account_result) { JobberAccount.find(jobber_account.id) }
        let(:data) { { webHookEvent: { topic: "APP_DISCONNECT", accountId: "test" } } }

        before do
          allow(ActiveSupport::SecurityUtils).to(receive(:secure_compare).and_return(true))

          post :index, params: params, xhr: true
        end

        it "should respond success" do
          expect(response).to(have_http_status(:ok))
        end

        it "should clear Jobber account credentials" do
          expect(jobber_account_result.id).to(eq(jobber_account.id))
          expect(jobber_account_result.jobber_access_token).to(be_nil)
          expect(jobber_account_result.jobber_access_token_expired_by).to(be_nil)
          expect(jobber_account_result.jobber_refresh_token).to(be_nil)
        end
      end

      context "with no account id" do
        let(:data) { { webHookEvent: { topic: "APP_DISCONNECT" } } }

        it "should respond bad_request" do
          allow(ActiveSupport::SecurityUtils).to(receive(:secure_compare).and_return(true))

          post :index, params: params, xhr: true

          expect(response).to(have_http_status(:bad_request))
        end
      end
    end
  end
end
