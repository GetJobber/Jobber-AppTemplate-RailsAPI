# frozen_string_literal: true

Rails.application.routes.draw do
  resources :jobber_accounts

  get "/heartbeat", to: "application#heartbeat"
  post "/request_access_token", to: "auth#request_oauth2_access_token"
end
