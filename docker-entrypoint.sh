#!/bin/sh

set -e

echo "Environment: $RAILS_ENV"

# Check bundle and install missing gems
bundle check || bundle install --jobs $(nproc --all) --retry 5

# Remove pre-existing puma/passenger server.pid
if [ -f /app/tmp/pids/server.pid ]; then
  rm -f /app/tmp/pids/server.pid
fi

# Create and migrate database
bundle exec rails db:create db:migrate

# Run anything by prepending bundle exec to the passed command
bundle exec rails server -b 0.0.0.0 -p 8080
