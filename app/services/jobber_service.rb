# frozen_string_literal: true

class JobberService
  AccountQuery = JobberAppTemplateRailsApi::Client.parse(<<~'GRAPHQL')
    query {
      account {
        id
        name
      }
    }
  GRAPHQL

  def execute_query(token)
    context = { Authorization: "Bearer #{token}" }
    JobberAppTemplateRailsApi::Client.query(AccountQuery, context: context)
  end

  def create_oauth2_access_token(code)
    tokens = client.auth_code.get_token(code)
    return if tokens.nil?

    tokens = tokens.to_hash
    tokens[:expires_at] = Time.at(JWT.decode(tokens[:access_token], nil, false).first["exp"]).utc.to_time
    tokens
  end

  def authenticate_account(tokens)
    result = execute_query(tokens[:access_token])

    return if result.blank?

    account_data = result.original_hash["data"]["account"]
    account_params = {
      jobber_id: account_data["id"],
      name: account_data["name"],
    }

    update_account_tokens(account_params, tokens)
  end

  def update_account_tokens(account_params, tokens)
    account = JobberAccount.find_or_create_by(account_params)
    account.jobber_access_token = tokens[:access_token]
    account.jobber_access_token_expired_by = tokens[:expires_at]
    account.jobber_refresh_token = tokens[:refresh_token]
    account.save!
    account
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

  def redirect_uri
    Rails.configuration.x.jobber.redirect_uri
  end
end
