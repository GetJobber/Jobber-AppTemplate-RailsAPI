# frozen_string_literal: true

class JobberService
  include Graphql::Queries::Account

  def execute_query(token, query, variables = {}, expected_cost: nil)
    context = { Authorization: "Bearer #{token}" }
    result = JobberAppTemplateRailsApi::Client.query(query, variables: variables, context: context)
    result = result.original_hash

    result_has_errors?(result)
    sleep_before_throttling(result, expected_cost)
    result
  end

  def execute_paginated_query(token, query, variables, resource_names, paginated_results = [], expected_cost: nil)
    result = execute_query(token, query, variables, expected_cost: expected_cost)

    result = result["data"]

    resource_names.each do |resource|
      result = result[resource].deep_dup
    end

    paginated_results << result["nodes"]
    page_info = result["pageInfo"]
    has_next_page = page_info["hasNextPage"]

    if has_next_page
      variables[:cursor] = page_info["endCursor"]
      execute_paginated_query(token, query, variables, resource_names, paginated_results, expected_cost: expected_cost)
    end

    paginated_results.flatten
  end

  def create_oauth2_access_token(code)
    tokens = client.auth_code.get_token(code)
    return if tokens.nil?

    tokens = tokens.to_hash
    tokens[:expires_at] = Time.at(JWT.decode(tokens[:access_token], nil, false).first["exp"]).utc.to_time
    tokens
  end

  def authenticate_account(tokens)
    result = execute_query(tokens[:access_token], AccountQuery)

    return if result.blank?

    account_data = result["data"]["account"]
    account_params = {
      jobber_id: account_data["id"],
      name: account_data["name"],
    }

    update_account_tokens(account_params, tokens)
  end

  def update_account_tokens(account_params, tokens)
    account = JobberAccount.find_or_create_by({ jobber_id: account_params[:jobber_id] })
    account.name = account_params[:name]
    account.jobber_access_token = tokens[:access_token]
    account.jobber_access_token_expired_by = tokens[:expires_at]
    account.jobber_refresh_token = tokens[:refresh_token]
    account.save!
    account
  end

  def refresh_access_token(account)
    raise Exceptions::AuthorizationException if account.jobber_access_token.blank?

    credentials = {
      token_type: "bearer",
      access_token: account.jobber_access_token,
      expires_at: account.jobber_access_token_expired_by,
      refresh_token: account.jobber_refresh_token,
    }

    tokens = OAuth2::AccessToken.from_hash(client, credentials)
    tokens = tokens.refresh!
    return if tokens.nil?

    tokens = tokens.to_hash
    tokens[:expires_at] = Time.at(JWT.decode(tokens[:access_token], nil, false).first["exp"]).utc.to_time
    tokens
  end

  private

  def client
    OAuth2::Client.new(client_id, client_secret, site: api_url)
  end

  def client_id
    Rails.configuration.x.jobber.client_id
  end

  def client_secret
    Rails.configuration.x.jobber.client_secret
  end

  def api_url
    Rails.configuration.x.jobber.api_url
  end

  def result_has_errors?(result)
    return false if result["errors"].nil?

    raise Exceptions::GraphQLQueryError, result["errors"].first["message"]
  end

  def sleep_before_throttling(result, expected_cost = nil)
    throttle_status = result["extensions"]["cost"]["throttleStatus"]
    currently_available = throttle_status["currentlyAvailable"].to_i
    max_available = throttle_status["maximumAvailable"].to_i
    restore_rate = throttle_status["restoreRate"].to_i
    sleep_time = 0

    if expected_cost.blank?
      expected_cost = max_available * 0.6
    end
    if currently_available <= expected_cost
      sleep_time = ((max_available - currently_available) / restore_rate).ceil
      sleep(sleep_time)
    end

    sleep_time
  end
end
