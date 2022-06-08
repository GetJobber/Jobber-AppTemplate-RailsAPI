# frozen_string_literal: true

module Exceptions
  class GraphQLQueryError < StandardError; end

  class AuthorizationException < StandardError
    def initialize(message = nil)
      super(message || "Unauthorized")
    end
  end
end
