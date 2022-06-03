# frozen_string_literal: true

namespace :schema do
  desc "Task to fetch latest schema and update JSON file"
  task update: :environment do
    GraphQL::Client.dump_schema(JobberAppTemplateRailsApi::HTTP, "db/schema.json")
  end
end
