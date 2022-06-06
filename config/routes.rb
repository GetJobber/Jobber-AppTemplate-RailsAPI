# frozen_string_literal: true

Rails.application.routes.draw do
  resources :jobber_accounts

  get "/heartbeat", to: "application#heartbeat"
  post "/request_access_token", to: "auth#request_oauth2_access_token"
  get "/jobber_account_name", to: "jobber_accounts#jobber_account_name"
end
