# Jobber App Template - Rails API

[![CircleCI](https://circleci.com/gh/GetJobber/Jobber-AppTemplate-RailsAPI/tree/main.svg?style=svg&circle-token=6b380bcc34004fc33fd7d0a8041ef80e20fe522d)](https://circleci.com/gh/GetJobber/Jobber-AppTemplate-RailsAPI/tree/main)

The primary objective of this Ruby on Rails API template is to provide a starting point to integrate your app with [Jobber](https://getjobber.com).

## Getting Started

### Prerequisites

- Ruby 3.0.1

  `rvm install "ruby-3.0.1"`

  `rvm use "ruby-3.0.1"`

- Postgres database

  - Install Docker:
    - [Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
    - [MacOS](https://docs.docker.com/desktop/mac/install/)
    - [Desktop](https://docs.docker.com/desktop/windows/install/)

- Jobber App
  - Create a developer account:
    - [https://developer.getjobber.com/](https://developer.getjobber.com/)
  - Create new app:
    - Follow the docs to get started: [https://developer.getjobber.com/docs](https://developer.getjobber.com/docs)

### Setup

1. Install gems

   `bundle install`

2. Create postgres and redis docker container

   `docker compose up -d`

3. Setup environment variables

   `cp .env.sample .env`

   Make sure to have the correct env values

4. Create database and migrations

   `rails db:create`

   `rails db:migrate`

### Run the app

`rails s`

## Making GraphQL requests

- Learn more about Jobber's GraphQL API:
  - [About Jobber's API](https://developer.getjobber.com/docs/#about-jobbers-api)

## Deployment

This template comes with a `Procfile` configured so you can easily deploy on [Heroku](https://heroku.com), however, you can deploy this API on the platform of your choice.

### Deploying with Heroku

1. Install the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli#install-the-heroku-cli).

2. Log in to you Heroku account:

`heroku login`

3. Create a new Heroku app, this can be done from your browser or using Heroku's CLI in your terminal:

`heroku create <name-of-your-app>`

4. Verify the git remote was added with `git config --list --local | grep heroku` or add the heroku remote yourself:

`git remote add heroku <heroku-app-url>`

5. Deploy

`git push heroku main`

To learn more about deploying on Heroku:

- [https://devcenter.heroku.com/categories/deployment](https://devcenter.heroku.com/categories/deployment)

## Learn More

Checkout [Jobber's API documentation](https://developer.getjobber.com/docs/) for more details on its setup and usage.

You can learn more about Ruby on Rails API mode in the [documentation](https://guides.rubyonrails.org/api_app.html).

For more information on Heroku, visit the [Heroku Dev Center](https://devcenter.heroku.com/) or the [Getting started on Heroku with Rails 6](https://devcenter.heroku.com/articles/getting-started-with-rails6) for more specific content on Rails.

## License

The template is available as open source under the terms of the MIT License.
