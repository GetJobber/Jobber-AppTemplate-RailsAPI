# frozen_string_literal: true

class ApplicationController < ActionController::API
  def heartbeat
    head(:ok)
  end
end
