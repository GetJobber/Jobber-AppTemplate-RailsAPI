# frozen_string_literal: true

class JobberAccountsController < ApplicationController
  def jobber_account_name
    render(json: { accountName: @jobber_account.name })
  end
end
