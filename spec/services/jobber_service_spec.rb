# frozen_string_literal: true

require "rails_helper"

RSpec.describe(JobberService, type: :service) do
  let!(:jobber_account) { create(:jobber_account) }
  let(:token) { "access_token" }
  let(:context) { { "Authorization": "Bearer #{token}" } }
  let(:query) { "query testGraphql {}" }
  let(:variables) { { test_field1: "value 1", test_field2: "value 2" } }
  let(:extensions_cost) do
    {
      "cost" => {
        "requestedQueryCost" => 1000,
        "actualQueryCost" => 900,
        "throttleStatus" => {
          "maximumAvailable" => 10000,
          "currentlyAvailable" => 9940,
          "restoreRate" => 500,
        },
      },
    }
  end
  let(:query_result) do
    query_result = OpenStruct.new
    query_result.original_hash = {
      "data" => {
        "test" => {
          "nodes" => [{ "id" => "test_id_1", "title" => "Test title 1" }],
          "pageInfo" => { "endCursor" => "MQ", "hasNextPage" => true },
        },
      },
      "extensions" => extensions_cost,
    }

    query_result
  end
  let(:tokens_result) do
    {
      access_token: "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOjEwNzc5ODgsImlzcyI6Imh0dHBzOi8vYXBpLmdldGpvYm" \
        "Jlci5jb20iLCJjbGllbnRfaWQiOiIyMWMzMTQ2NS03YjBhLTQ4NmYtYmZkMy1hYTJjMmMyOWYyOTMiLCJzY29wZ" \
        "SI6InJlYWRfY2xpZW50cyByZWFkX3VzZXJzIiwiYXBwX2lkIjoiMjFjMzE0NjUtN2IwYS00ODZmLWJmZDMtYWEy" \
        "YzJjMjlmMjkzIiwidXNlcl9pZCI6MTA3Nzk4OCwiYWNjb3VudF9pZCI6NDMwMTE0LCJleHAiOjE2NTUxNDA2MTd" \
        "9.5OwyIy8g4h6LGqyGtpcl9L-dSG33gzjtm80RJwPBMeI",
      refresh_token: "23792a2304922e1c658abb4725b4b8d2",
      expires_at: nil,
    }
  end
  let(:expires_at) { Time.at(JWT.decode(tokens_result[:access_token], nil, false).first["exp"]).utc.to_time }

  describe "#execute_query" do
    let(:result) { described_class.new.execute_query(token, query, variables) }

    before do
      allow(JobberAppTemplateRailsApi::Client).to(
        receive(:query).with(query, variables: variables, context: context).and_return(query_result),
      )

      result
    end

    context "executes the query with arguments" do
      it {
        expect(JobberAppTemplateRailsApi::Client).to(have_received(:query).with(
          query, variables: variables, context: context
        ))
      }
      it { expect(result).to(eq(query_result.original_hash)) }
    end
  end

  describe "#execute_paginated_query" do
    let(:variables2) { { cursor: "MQ", test_field1: "value 1", test_field2: "value 2" } }
    let(:resource_names) { ["test"] }
    let(:query_result2) do
      query_result = OpenStruct.new
      query_result.original_hash = {
        "data" => {
          "test" => {
            "nodes" => [{ "id" => "test_id_2", "title" => "Test title 2" }],
            "pageInfo" => { "endCursor" => "Mg", "hasNextPage" => false },
          },
        },
        "extensions" => extensions_cost,
      }

      query_result
    end

    let(:paginated_results) do
      [{ "id" => "test_id_1", "title" => "Test title 1" }, { "id" => "test_id_2", "title" => "Test title 2" }]
    end

    let(:result) { described_class.new.execute_paginated_query(token, query, variables, resource_names) }

    before do
      allow(JobberAppTemplateRailsApi::Client).to(
        receive(:query).with(query, variables: variables, context: context).and_return(query_result),
      )
      allow(JobberAppTemplateRailsApi::Client).to(
        receive(:query).with(query, variables: variables2, context: context).and_return(query_result2),
      )
    end

    context "returns formated paginated results" do
      it { expect(result).to(eq(paginated_results)) }
    end
  end

  describe "#create_oauth2_access_token" do
    let(:result) { described_class.new.create_oauth2_access_token("123") }

    before do
      allow_any_instance_of(OAuth2::Client).to(receive_message_chain(:auth_code, :get_token).and_return(tokens_result))
    end

    it "create tokens with expires_at attribute" do
      expect(result[:access_token]).to(eq(tokens_result[:access_token]))
      expect(result[:refresh_token]).to(eq(tokens_result[:refresh_token]))
      expect(result[:expires_at]).to(eq(expires_at))
    end

    context "when tokens are nil" do
      before { allow_any_instance_of(OAuth2::Client).to(receive_message_chain(:auth_code, :get_token).and_return(nil)) }

      it { expect(result).to(be_nil) }
    end
  end

  describe "#authenticate_account" do
    let(:account_id) { jobber_account.jobber_id }
    let(:account_name) { jobber_account.name }
    let(:account_data) do
      {
        "data" => {
          "account" => {
            "id" => account_id,
            "name" => account_name,
          },
        },
      }
    end
    let(:tokens) do
      {
        access_token: "test token",
      }
    end
    let(:result) { described_class.new.authenticate_account(tokens) }

    before do
      allow_any_instance_of(described_class).to(receive(:execute_query).and_return(account_data))
    end

    context "when account already exists" do
      it "should update the tokens of the existing jobber_account" do
        expect { result }.to_not(change { JobberAccount.count })
        expect(result.jobber_id).to(eq(account_id))
        expect(result.name).to(eq(account_name))
        expect(result.jobber_access_token).to(eq(tokens[:access_token]))
        expect(result.jobber_access_token_expired_by).to(eq(tokens[:expires_at]))
        expect(result.jobber_refresh_token).to(eq(tokens[:refresh_token]))
      end
    end

    context "when it is a new account" do
      let(:account_id) { "1234" }
      let(:account_name) { "New account name" }

      it "should create a new jobber_account and set the tokens" do
        expect { result }.to(change { JobberAccount.count }.by(1))
        expect(result.jobber_id).to(eq(account_id))
        expect(result.name).to(eq(account_name))
        expect(result.jobber_access_token).to(eq(tokens[:access_token]))
        expect(result.jobber_access_token_expired_by).to(eq(tokens[:expires_at]))
        expect(result.jobber_refresh_token).to(eq(tokens[:refresh_token]))
      end
    end
  end

  describe "#refresh_access_token" do
    let(:oauth2_mock) do
      query_result = Object.new

      query_result.class.define_method(:refresh!) do
        {
          access_token: "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOjEwNzc5ODgsImlzcyI6Imh0dHBzOi8vYXBpLmdldGpvYm" \
            "Jlci5jb20iLCJjbGllbnRfaWQiOiIyMWMzMTQ2NS03YjBhLTQ4NmYtYmZkMy1hYTJjMmMyOWYyOTMiLCJzY29wZ" \
            "SI6InJlYWRfY2xpZW50cyByZWFkX3VzZXJzIiwiYXBwX2lkIjoiMjFjMzE0NjUtN2IwYS00ODZmLWJmZDMtYWEy" \
            "YzJjMjlmMjkzIiwidXNlcl9pZCI6MTA3Nzk4OCwiYWNjb3VudF9pZCI6NDMwMTE0LCJleHAiOjE2NTUxNDA2MTd" \
            "9.5OwyIy8g4h6LGqyGtpcl9L-dSG33gzjtm80RJwPBMeI",
          refresh_token: "23792a2304922e1c658abb4725b4b8d2",
          expires_at: nil,
        }
      end

      query_result
    end
    let(:result) { described_class.new.refresh_access_token(jobber_account) }

    before { allow(OAuth2::AccessToken).to(receive(:from_hash).and_return(oauth2_mock)) }

    context "when access token is nil" do
      before do
        jobber_account.jobber_access_token = nil
        jobber_account.save!
      end

      it { expect { result }.to(raise_error(Exceptions::AuthorizationException)) }
    end

    context "when tokens are nil" do
      let(:oauth2_mock) do
        query_result = Object.new

        query_result.class.define_method(:refresh!) do
          nil
        end

        query_result
      end

      it { expect(result).to(be_nil) }
    end

    context "when tokens refresh successfully" do
      it "create tokens with expires_at attribute" do
        expect(result[:access_token]).to(eq(tokens_result[:access_token]))
        expect(result[:refresh_token]).to(eq(tokens_result[:refresh_token]))
        expect(result[:expires_at]).to(eq(expires_at))
      end
    end
  end

  describe "#result_has_errors?" do
    let(:throttling_error) do
      {
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
    end
    let(:data) do
      {
        "data" => "no errors",
        "extensions" => extensions_cost,
      }
    end

    context "when query result has errors" do
      let(:result) { described_class.new.send(:result_has_errors?, throttling_error) }

      it "raises the error with a message" do
        expect { result }.to(raise_error(Exceptions::GraphQLQueryError, "Throttled"))
      end
    end

    context "when query result has no errors" do
      let(:result) { described_class.new.send(:result_has_errors?, data) }

      it "returns false" do
        expect(result).to(eq(false))
      end
    end
  end

  describe "#sleep_before_throttling" do
    let(:currently_available) { 3500 }
    let(:max_available) { 10000 }
    let(:restore_rate) { 500 }
    let(:sleep_time) { ((max_available - currently_available) / restore_rate).ceil }
    let(:query_result) do
      query_result = {
        "data" => {},
        "extensions" => extensions_cost,
      }

      query_result
    end
    let(:result) { described_class.new.send(:sleep_before_throttling, query_result) }
    before do
      allow_any_instance_of(described_class).to(receive(:sleep).with(sleep_time).and_return("lol"))
    end

    context "when currently available points are below 60% of maximum available points" do
      let(:extensions_cost) do
        {
          "cost" => {
            "requestedQueryCost" => 7000,
            "actualQueryCost" => 6500,
            "throttleStatus" => {
              "maximumAvailable" => max_available,
              "currentlyAvailable" => currently_available,
              "restoreRate" => restore_rate,
            },
          },
        }
      end

      it "sleeps" do
        expect_any_instance_of(described_class).to(receive(:sleep).with(sleep_time))

        result
      end
    end

    context "when currently available points are above 60% of maximum available points" do
      it "does not sleep" do
        expect_any_instance_of(described_class).not_to(receive(:sleep).with(sleep_time))

        result
      end
    end
  end
end
