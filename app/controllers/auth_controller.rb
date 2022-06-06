# frozen_string_literal: true

class AuthController < ApplicationController
  def request_oauth2_access_token
    tokens = jobber_service.create_oauth2_access_token(params[:code].to_s)

    return if tokens.blank? || tokens[:access_token].blank?

    account = jobber_service.authenticate_account(tokens)

    return if account.blank?

    response.set_cookie(
      :jobber_account_id,
      {
        value: account.jobber_id,
        expires: tokens[:expires_at],
        httponly: true,
        secure: Rails.env.production?,
      }
    )
    render(status: :ok)
  end

  private

  def jobber_service
    JobberService.new
  end
end
