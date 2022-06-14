# frozen_string_literal: true

require "rails_helper"

RSpec.describe(JobberAccount, type: :model) do
  let(:jobber_account) { create(:jobber_account) }

  describe "#clear_jobber_credentials!" do
    let(:jobber_account_result) { JobberAccount.find(jobber_account.id) }

    before { jobber_account.clear_jobber_credentials! }

    it "should clear jobber account tokens" do
      expect(jobber_account_result.jobber_access_token).to(be_nil)
      expect(jobber_account_result.jobber_access_token_expired_by).to(be_nil)
      expect(jobber_account_result.jobber_refresh_token).to(be_nil)
    end
  end

  describe "#valid_jobber_access_token?" do
    let(:result) { jobber_account.valid_jobber_access_token? }

    context "when token is expired" do
      let(:jobber_account) { create(:jobber_account, jobber_access_token_expired_by: Time.now - 10.minutes) }

      it { expect(result).to(be_falsy) }
    end

    context "when token is not expired" do
      let(:jobber_account) { create(:jobber_account, jobber_access_token_expired_by: Time.now + 10.minutes) }

      it { expect(result).to(be_truthy) }
    end
  end

  describe "#refresh_jobber_access_token!" do
    let(:tokens) { nil }
    let(:result) { jobber_account.refresh_jobber_access_token! }

    before { allow_any_instance_of(JobberService).to(receive(:refresh_access_token).and_return(tokens)) }

    context "when service returns no access token" do
      let(:tokens) { nil }

      it { expect { result }.to(raise_error(StandardError, "Jobber token refresh failed")) }
    end

    context "when service returns tokens" do
      let(:tokens) do
        {
          access_token: "test access token",
          expires_at: Time.now + 30.minutes,
          refresh_token: "test refresh token",
        }
      end

      before { result }

      it "should update jobber account tokens" do
        expect(result.jobber_access_token).to(eq(tokens[:access_token]))
        expect(result.jobber_access_token_expired_by).to(eq(tokens[:expires_at]))
        expect(result.jobber_refresh_token).to(eq(tokens[:refresh_token]))
      end
    end
  end
end
