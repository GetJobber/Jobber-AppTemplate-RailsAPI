# frozen_string_literal: true

FactoryBot.define do
  factory :jobber_account do
    jobber_id { Faker::Internet.uuid }
    name { Faker::Name.unique.name }
    jobber_access_token { "jobber access token" }
    jobber_access_token_expired_by { Time.now + 10.minutes }
    jobber_refresh_token { "jobber refresh token" }
  end
end
