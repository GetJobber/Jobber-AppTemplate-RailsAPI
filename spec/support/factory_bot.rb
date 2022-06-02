# frozen_string_literal: true

require "factory_bot"

RSpec.configure do |config|
  config.before(:suite) { FactoryBot.reload }
  config.include(FactoryBot::Syntax::Methods)
end
