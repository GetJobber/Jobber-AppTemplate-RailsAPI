# frozen_string_literal: true

require "rails_helper"

RSpec.describe(ApplicationController) do
  let!(:jobber_account) { create(:jobber_account) }

  describe "#heartbeat", type: :controller do
    before { get :heartbeat }

    context "should return 200 status code" do
      it { expect(response).to(have_http_status(:ok)) }
    end
  end

  describe "#validade_session" do
    let(:result) { described_class.new.send(:validate_session) }

    context "when there is no session" do
      before do
        allow_any_instance_of(described_class).to(receive(:jobber_account_id).and_return(nil))
        allow_any_instance_of(described_class).to(receive(:render).and_return("Unauthorized"))
      end

      it "returns Unauthorized" do
        expect(result).to(eq("Unauthorized"))
      end
    end

    context "when session is invalid" do
      before do
        allow_any_instance_of(described_class).to(receive(:jobber_account_id).and_return("1234"))
        allow_any_instance_of(described_class).to(receive(:render).and_return("Unauthorized"))
      end

      it "returns Unauthorized" do
        expect(result).to(eq("Unauthorized"))
      end
    end

    context "when session has a valid jobber_id" do
      before do
        allow_any_instance_of(described_class).to(receive(:jobber_account_id).and_return(jobber_account.jobber_id))
      end

      context "when access token is valid" do
        it "does not call jobber_account refresh_jobber_access_token! method" do
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

        it "calls jobber_account refresh_jobber_access_token! method" do
          expect_any_instance_of(JobberAccount).to(receive(:refresh_jobber_access_token!))
          result
        end
      end
    end
  end
end
