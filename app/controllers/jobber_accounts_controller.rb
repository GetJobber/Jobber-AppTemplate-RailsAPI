# frozen_string_literal: true

class JobberAccountsController < ApplicationController
  before_action :set_jobber_account, only: [:show, :update, :destroy]

  # GET /jobber_accounts
  def index
    @jobber_accounts = JobberAccount.all

    render(json: @jobber_accounts)
  end

  # GET /jobber_accounts/1
  def show
    render(json: @jobber_account)
  end

  # POST /jobber_accounts
  def create
    @jobber_account = JobberAccount.new(jobber_account_params)

    if @jobber_account.save
      render(json: @jobber_account, status: :created, location: @jobber_account)
    else
      render(json: @jobber_account.errors, status: :unprocessable_entity)
    end
  end

  # PATCH/PUT /jobber_accounts/1
  def update
    if @jobber_account.update(jobber_account_params)
      render(json: @jobber_account)
    else
      render(json: @jobber_account.errors, status: :unprocessable_entity)
    end
  end

  # DELETE /jobber_accounts/1
  def destroy
    @jobber_account.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_jobber_account
    @jobber_account = JobberAccount.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def jobber_account_params
    params.require(:jobber_account).permit(:jobber_id, :name, :jobber_access_token, :jobber_access_token_expired_by,
      :jobber_refresh_token)
  end
end
