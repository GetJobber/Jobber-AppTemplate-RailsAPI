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
        httponly: true,
        secure: Rails.env.production?,
      }
    )
    render(json: { accountName: account.name })
  end

  def logout
    response.delete_cookie("jobber_account_id")
    head(:ok)
  end

  private

  def jobber_service
    JobberService.new
  end

  def jobber_account_id
    request.cookies["jobber_account_id"]
  end

  def set_jobber_account
    @jobber_account = JobberAccount.find_by(jobber_id: jobber_account_id)
  end

  def valid_access_token?
    raise Exceptions::AuthorizationException if jobber_account_id.blank?

    set_jobber_account

    raise Exceptions::AuthorizationException if @jobber_account.blank?

    @jobber_account.valid_jobber_access_token?
  end

  def refresh_access_token
    @jobber_account.refresh_jobber_access_token!
  end

  def validate_user_session
    refresh_access_token unless valid_access_token?
  rescue Exceptions::AuthorizationException => error
    render(json: { message: error.message }, status: :unauthorized)
  end
end
