# frozen_string_literal: true

class JobberAccountsController < AuthController
  before_action :validate_user_session

  def jobber_account_name
    render(json: { jobber_account_name: @jobber_account.name })
  end
end
