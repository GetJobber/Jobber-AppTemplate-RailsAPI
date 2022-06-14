# Jobber App Template - Rails API

The primary objective of this Ruby on Rails API template is to provide a starting point to integrate your app with [Jobber](https://getjobber.com).

[Demo](https://jobber-app-template-rails-api.herokuapp.com/)

## Getting Started

### Prerequisites 🛠️

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

### Setup ⚙️

1. Install gems

    `bundle install`

3. Create postgres and redis docker container
    
    `docker compose up -d`

4. Setup environment variables
   
   `cp .env.sample .env`
   
   Make sure to have the correct env values

5. Create database and migrations
    
    `rails db:create`
    
    `rails db:migrate`

### Run the app 🔥    
    
  `rails s`
  
## Making GraphQL requests

  - Learn more about Jobber's GraphQL API:
    - [About Jobber's API](https://developer.getjobber.com/docs/#about-jobbers-api)

## Deployment 🚀

  This template comes with a `Procfile` configured so you can easily deploy on [Heroku](https://heroku.com), learn more about deploying on Heroku:
  - [https://devcenter.heroku.com/categories/deployment](https://devcenter.heroku.com/categories/deployment)
    
## License

  The template is available as open source under the terms of the MIT License.
  
