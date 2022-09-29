# frozen_string_literal: true

class ClientsController < ApplicationController
  include Graphql::Queries::Clients

  def index
    token = @jobber_account.jobber_access_token
    clients = JobberService.new.execute_paginated_query(token, ClientsQuery, variables, ["clients"])

    render(json: { clients: clients }, status: :ok)
  rescue Exceptions::GraphQLQueryError => error
    render(json: { message: "#{error.class}: #{error.message}" }, status: :internal_server_error)
  end
end
