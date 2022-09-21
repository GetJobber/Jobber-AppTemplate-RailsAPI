# frozen_string_literal: true

require "rails_helper"

RSpec.describe(ClientsController, type: :controller) do
  let(:jobber_account) { create(:jobber_account) }
  let(:result) { JSON.parse(response.body) }

  before do
    allow(request).to(receive(:session).and_return({ account_id: jobber_account.jobber_id }))
  end

  describe "#index" do
    context "when query is executed successfully" do
      let(:clients_querry_result) do
        [
          {
            "id" => "Z2lkOi8vSm9iYmVyL0NsaWVudC80NjQ0OTMyNw==",
            "name" => "Arthas Menethil",
          },
          {
            "id" => "Z2lkOi8vSm9iYmVyL0NsaWVudC80NDkwNjcxMg==",
            "name" => "Jaina Proudmore",
          },
        ]
      end

      before do
        allow_any_instance_of(JobberService).to(receive(:execute_paginated_query).and_return(clients_querry_result))

        get :index
      end

      it { expect(response).to(have_http_status(:ok)) }

      it "should return the list of clients" do
        expect(result["clients"]).to(eq(clients_querry_result))
      end
    end

    context "when query_result returns errors" do
      let(:throttling_error) do
        query_result = OpenStruct.new
        query_result.original_hash = {
          "errors" => [
            {
              "message" => "Throttled",
              "extensions" => {
                "code" => "THROTTLED",
                "documentation" => "https://developer.getjobber.com/docs/build_with_jobber/api_rate_limits",
              },
            },
          ],
        }
        query_result
      end

      before do
        allow(JobberAppTemplateRailsApi::Client).to(receive(:query).and_return(throttling_error))

        get :index
      end

      it { expect(response).to(have_http_status(:internal_server_error)) }

      it { expect(result["message"]).to(eq("Exceptions::GraphQLQueryError: Throttled")) }
    end
  end
end
