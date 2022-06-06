# frozen_string_literal: true

module Graphql
  module Queries
    module Clients
      CLIENTS_LIMIT = 50

      def variables
        {
          limit: CLIENTS_LIMIT,
          cursor: nil,
          filter: nil,
        }
      end

      ClientsQuery = JobberAppTemplateRailsApi::Client.parse(<<~'GRAPHQL')
        fragment PageInfoFragment on PageInfo {
          endCursor
          hasNextPage
        }
        query(
          $limit: Int,
          $cursor: String,
          $filter: ClientFilterAttributes,
        ) {
          clients(first: $limit, after: $cursor, filter: $filter) {
            nodes {
              id
              name
            }
            pageInfo {
              ...PageInfoFragment
            }
          }
        }
      GRAPHQL
    end
  end
end
