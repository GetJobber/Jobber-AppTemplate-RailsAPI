# frozen_string_literal: true

class ClientsController < ApplicationController
  include Graphql::Queries::Clients

  before_action :set_jobber_account, only: [:index]

  def index
    token = @jobber_account.jobber_access_token
    clients = jobber_service.execute_paginated_query(
      token,
      ClientsQuery,
      variables,
      ["clients"],
    )

    render(json: { clients: clients }, status: :ok)
  rescue => error
    render(json: { error: "#{error.class}: #{error.message}" }, status: :internal_server_error)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_jobber_account
    jobber_account_id = request.cookies["jobber_account_id"]
    @jobber_account = JobberAccount.find_by(jobber_id: jobber_account_id)
  end

  def jobber_service
    JobberService.new
  end
end
