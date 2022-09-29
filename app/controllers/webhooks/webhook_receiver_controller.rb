# frozen_string_literal: true

module Webhooks
  class WebhookReceiverController < ApplicationController
    before_action :webhook_source_validation
    skip_before_action :validate_session

    def index
      case params[:data][:webHookEvent][:topic]
      when "APP_DISCONNECT"
        disconnect

        render(json: { "message" => "App disconnected" }, status: :ok)
      else
        render(json: { "message" => "Invalid topic provided" }, status: :bad_request)
      end
    rescue StandardError
      head(:bad_request)
    end

    private

    def disconnect
      account_id = params[:data][:webHookEvent][:accountId]
      raise if account_id.blank?

      response.delete_cookie("jobber_account_id")

      account = JobberAccount.find_by(jobber_id: account_id)
      return if account.blank?

      account.clear_jobber_credentials!
    end

    def webhook_source_validation
      calculated_hmac = Base64.strict_encode64(
        OpenSSL::HMAC.digest(
          "sha256",
          Rails.configuration.x.jobber.client_secret || "",
          ActiveSupport::JSON.encode({ data: params[:data] }),
        ),
      )

      head(:unauthorized) unless ActiveSupport::SecurityUtils.secure_compare(
        calculated_hmac,
        request.headers["X-Jobber-Hmac-SHA256"],
      )
    rescue StandardError
      head(:unauthorized)
    end
  end
end
