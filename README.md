# Jobber App Template - Rails API

[![CircleCI](https://circleci.com/gh/GetJobber/Jobber-AppTemplate-RailsAPI/tree/main.svg?style=svg&circle-token=6b380bcc34004fc33fd7d0a8041ef80e20fe522d)](https://circleci.com/gh/GetJobber/Jobber-AppTemplate-RailsAPI/tree/main)

The primary objective of this Ruby on Rails API template is to provide a starting point to integrate your app with [Jobber](https://getjobber.com).

## Table of contents

- [What is this App for?](#what-is-this-app-for)
- [OAuth flow](#oauth-flow)
- [How it works](#how-it-works)
  - [Forming a GraphQL Query](#forming-a-graphql-query)
  - [Making a Query request](#making-a-query-request)
  - [Putting it all together](#putting-it-all-together)
  - [Expected result](#expected-result)
- [Getting started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Setup](#setup)
  - [Running the app](#running-the-app)
- [Making GraphQL requests](#making-graphql-requests)
- [Deployment](#deployment)
  - [Deploying with Heroku](#deploying-with-heroku)
- [Learn More](#learn-more)
- [Need help of have an idea?](#need-help-or-have-an-idea)
- [License](#license)

## What is this APP for?

This Ruby on Rails API Template is meant to be a quick and easy way to get you up to speed using Jobber's GraphQL API. This API is to be consumed by the [React App Template](https://github.com/GetJobber/Jobber-AppTemplate-React) and handles authentication through Jobber's Developer Center and a few GraphQL example queries.

## OAuth flow

The authentication flow is done by both apps, the frontend is responsable to receive the `code` returned from Jobber's GraphQL API once the users goes through the oauth and allow the app to connect to they jobber account.

On this App you will find a `/request_access_token` endpoint that will authenticate the user upon recieving a valid code, creating a record for a JobberAccount, generating an HttpOnly Cookie and sending it to the frontend in order to mantain the session.

> Note: An App needs to be created on Jobber's Developer Center, and the environment variables described in `.env.sample` need to be configured in order to make the oauth redirection.

## How it works

When you run both apps together, you should see a list of the clients from your Jobber account on the frontend:

### Forming a GraphQL Query

A sample query is available for getting paginated clients, you can try increasing the `CLIENTS_LIMIT` constant to get more clients per request which could trigger a Throttling error or decreasing it, which would then generate many more and smaller requests. Finding a _good balance_ is key to have an app with good performance.

Read more on [Jobber's API Rate Limits](https://developer.getjobber.com/docs/build_with_jobber/api_rate_limits).

```graphql
# app/services/queries/clients.rb
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
```

### Making a Query request

We use `execute_query` to make a simple request and make sure it won't cause any issues with `result_has_errors?` and `sleep_before_throttling`.

`execute_paginated_query` is a recursive method that will call `execute_query` until `has_next_page` is false, meaning we've reached the end of our query. This is where the `CLIENTS_LIMIT` constant in the ClientsQuery comes into play.

If for any reason the query returns an error, it will be raised by `result_has_errors?`.

Finally, `sleep_before_throttling` makes sure your query won't go over the [Maximum Available Limit](https://developer.getjobber.com/docs/build_with_jobber/api_rate_limits#maximumavailable) by taking the cost of the previous request as the `expected_cost` of the next request and comparing it against the currently available points.

```ruby
# app/services/jobber_service.rb
class JobberService

  def execute_query(token, query, variables = {}, expected_cost: nil)
    context = { Authorization: "Bearer #{token}" }
    result = JobberAppTemplateRailsApi::Client.query(query, variables: variables, context: context)
    result = result.original_hash

    result_has_errors?(result)
    sleep_before_throttling(result, expected_cost)
    result
  end

  def execute_paginated_query(token, query, variables, resource_names, paginated_results = [], expected_cost: nil)
    result = execute_query(token, query, variables, expected_cost: expected_cost)

    result = result["data"]

    resource_names.each do |resource|
      result = result[resource].deep_dup
    end

    paginated_results << result["nodes"]
    page_info = result["pageInfo"]
    has_next_page = page_info["hasNextPage"]

    if has_next_page
      variables[:cursor] = page_info["endCursor"]
      execute_paginated_query(token, query, variables, resource_names, paginated_results, expected_cost: expected_cost)
    end

    paginated_results.flatten
  end

  private

  def result_has_errors?(result)
    return false if result["errors"].nil?

    raise Exceptions::GraphQLQueryError, result["errors"].first["message"]
  end

  def sleep_before_throttling(result, expected_cost = nil)
    throttle_status = result["extensions"]["cost"]["throttleStatus"]
    currently_available = throttle_status["currentlyAvailable"].to_i
    max_available = throttle_status["maximumAvailable"].to_i
    restore_rate = throttle_status["restoreRate"].to_i
    sleep_time = 0

    if expected_cost.blank?
      expected_cost = max_available * 0.6
    end
    if currently_available <= expected_cost
      sleep_time = ((max_available - currently_available) / restore_rate).ceil
      sleep(sleep_time)
    end

    sleep_time
  end
end
```

### Putting it all together

`clients_controller#index` retrieves the account's access token to use as a parameter for the `execute_paginated_query` method along with the `ClientsQuery` and its `variables` and pass `["clients"]` as the `paginated_result` param. We don't pass an expected cost for this example, meaning `sleep_before_throttling` will be our default 60% of the Maximum Available Limit.

```ruby
# app/controllers/clients_controller.rb
class ClientsController < AuthController
  include Graphql::Queries::Clients

  def index
    token = @jobber_account.jobber_access_token
    clients = jobber_service.execute_paginated_query(token, ClientsQuery, variables, ["clients"])

    render(json: { clients: clients }, status: :ok)
  rescue Exceptions::GraphQLQueryError => error
    render(json: { message: "#{error.class}: #{error.message}" }, status: :internal_server_error)
  end
end
```

### Expected result

You should expect `clients_controller#index` to return a json similar to this:

```json
{
  "clients": [
    {
      "id": "ABC1DEFgHIE=",
      "name": "Anakin Skywalker"
    },
    {
      "id": "ABC1DEFgHIY=",
      "name": "Paddy's Pub"
    },
    {
      "id": "ABC1DEFgHIM=",
      "name": "Maximus Decimus Meridius"
    },
    {
      "id": "ABC1DEFgHIM=",
      "name": "Tom Bombadil"
    }
  ]
}
```

Which should look something like this on the frontend:

<img width="1728" alt="Screen Shot 2022-06-22 at 12 56 59" src="https://user-images.githubusercontent.com/804175/175104972-cf59f08d-e40c-441f-be90-cede6e7cceaf.png">

## Getting started

### Prerequisites

- Ruby 3.0.1

  - `rvm install "ruby-3.0.1"`

  - `rvm use "ruby-3.0.1"`

- Postgres database

  This project is configured to use the postgres database from the `docker-compose.yml` file.

  - Install Docker:
    - [Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
    - [MacOS](https://docs.docker.com/desktop/mac/install/)
    - [Desktop](https://docs.docker.com/desktop/windows/install/)

- Jobber App
  - Create a developer account:
    - [https://developer.getjobber.com/](https://developer.getjobber.com/)
  - Create new app:
    - Follow the docs to get started: [https://developer.getjobber.com/docs](https://developer.getjobber.com/docs)
    - Your app must have (as a minimum) read access to *Clients* and *Users* under the Scopes section, in order for this template to work:
      <img width="1728" alt="Screen Shot 2022-06-22 at 13 27 50" src="https://user-images.githubusercontent.com/804175/175111860-ad44f70d-5d33-4334-b5ff-afd677c22a04.png">


### Setup

1. Install gems

   - `bundle install`

2. Create postgres and redis docker container

   - `docker compose up -d`

3. Setup environment variables

   - `cp .env.sample .env`

     Make sure to have the correct env values

4. Create database and migrations

   - `rails db:create`

   - `rails db:migrate`

5. Update the GraphQL schema

   - `rake schema:update`

### Running the app

- `rails s -p 4000`

## Making GraphQL requests

- Learn more about Jobber's GraphQL API:
  - [About Jobber's API](https://developer.getjobber.com/docs/#about-jobbers-api)

## Deployment

This template comes with a `Procfile` configured so you can easily deploy on [Heroku](https://heroku.com), however, you can deploy this API on the platform of your choice.

### Deploying with Heroku

1. Install the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli#install-the-heroku-cli).

2. Log in to you Heroku account:

   - `heroku login`

3. Create a new Heroku app, this can be done from your browser or using Heroku's CLI in your terminal:

   - `heroku create <name-of-your-app>`

4. Verify the git remote was added with `git config --list --local | grep heroku` or add the heroku remote yourself:

   - `git remote add heroku <heroku-app-url>`

5. Deploy

   - `git push heroku main`

To learn more about deploying on Heroku:

- [https://devcenter.heroku.com/categories/deployment](https://devcenter.heroku.com/categories/deployment)

## Learn More

Checkout [Jobber's API documentation](https://developer.getjobber.com/docs/) for more details on its setup and usage.

You can learn more about Ruby on Rails API mode in the [documentation](https://guides.rubyonrails.org/api_app.html).

For more information on Heroku, visit the [Heroku Dev Center](https://devcenter.heroku.com/) or the [Getting started on Heroku with Rails 6](https://devcenter.heroku.com/articles/getting-started-with-rails6) for more specific content on Rails.

## Need help or have and idea?

Please follow one of these [issue templates](https://github.com/GetJobber/Jobber-AppTemplate-RailsAPI/issues/new/choose) if you'd like to submit a bug or request a feature.

## License

The template is available as open source under the terms of the MIT License.
