# frozen_string_literal: true

Rails.application.routes.draw do
  get "/heartbeat", to: "application#heartbeat"
end
