# frozen_string_literal: true

class ClientsController < AuthController
  include Graphql::Queries::Clients

  before_action :validate_user_session

  def index
    token = @jobber_account.jobber_access_token
    clients = jobber_service.execute_paginated_query(
      token,
      ClientsQuery,
      variables,
      ["clients"],
    )

    render(json: { clients: clients }, status: :ok)
  rescue Exceptions::GraphQLQueryError => error
    render(json: { error: "#{error.class}: #{error.message}" }, status: :internal_server_error)
  end
end
