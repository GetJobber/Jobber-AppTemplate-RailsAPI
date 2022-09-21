# frozen_string_literal: true

class JobberAccount < ApplicationRecord
  def clear_jobber_credentials!
    update!(
      jobber_access_token: nil,
      jobber_access_token_expired_by: nil,
      jobber_refresh_token: nil,
    )
  end

  def valid_jobber_access_token?
    jobber_access_token_expired_by.present? ? jobber_access_token_expired_by > Time.now.utc : false
  end

  def refresh_jobber_access_token!
    jobber_service = JobberService.new
    tokens = jobber_service.refresh_access_token(self)

    if tokens.nil? || tokens[:access_token].blank?
      Rails.logger.debug { "Unexpected failure of jobber token refresh" }
      clear_jobber_credentials!
      raise "Jobber token refresh failed"
    end

    update!(
      jobber_access_token: tokens[:access_token],
      jobber_access_token_expired_by: tokens[:expires_at],
      jobber_refresh_token: tokens[:refresh_token],
    )
    self
  end
end
