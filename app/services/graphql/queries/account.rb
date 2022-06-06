# frozen_string_literal: true

module Graphql
  module Queries
    module Account
      AccountQuery = JobberAppTemplateRailsApi::Client.parse(<<~'GRAPHQL')
        query {
          account {
            id
            name
          }
        }
      GRAPHQL
    end
  end
end
