# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :validate_session

  def request_oauth2_access_token
    tokens = jobber_service.create_oauth2_access_token(params[:code].to_s)

    return if tokens.blank? || tokens[:access_token].blank?

    account = jobber_service.authenticate_account(tokens)

    return if account.blank?

    session[:account_id] = account.jobber_id

    render(json: { accountName: account.name })
  end

  def logout
    reset_session
    head(:ok)
  end

  private

  def jobber_service
    JobberService.new
  end
end
