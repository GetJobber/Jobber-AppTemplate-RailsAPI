# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "graphql/client"
require "graphql/client/http"

# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module JobberAppTemplateRailsApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults(6.1)
    config.autoload_paths += ["#{Rails.root}/app/errors"]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.middleware.use(ActionDispatch::Cookies)
    config.middleware.use(ActionDispatch::Session::CookieStore)

    config.x.jobber.client_id = ENV["JOBBER_CLIENT_ID"]
    config.x.jobber.client_secret = ENV["JOBBER_CLIENT_SECRET"]
    config.x.jobber.api_url = ENV["JOBBER_API_URL"]
  end

  # Configure GraphQL endpoint using the basic HTTP network adapter.
  HTTP = GraphQL::Client::HTTP.new("#{ENV["JOBBER_API_URL"]}/graphql") do
    def headers(context)
      # Optionally set any HTTP headers
      context.merge!({ "X-JOBBER-GRAPHQL-VERSION": "2022-03-10" })
      context
    end
  end

  # Fetch latest schema on init, this will make a network request
  # Schema = GraphQL::Client.load_schema(HTTP)

  # However, it's smart to dump this to a JSON file and load from disk
  #
  # Run it from a script or rake task: rake schema:update
  # GraphQL::Client.dump_schema(JobberAppTemplateRailsApi::HTTP, "db/schema.json")
  Schema = GraphQL::Client.load_schema("db/schema.json")
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
end
