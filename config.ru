# Require only RACK_ENV var to set "production" etc
ENV["APP_ENV"] = ENV["RACK_ENV"]

require 'rack/protection'
require_relative './api'

# Add any required ENV vars to this array
def env_vars_present?
  [
    "RACK_ENV",
    "PORT",
    "AGGREGATE_RESULTS",
    "AGGREGATE_RESULTS_HOURS_DELAY",
    "BASIC_AUTH_USERNAME",
    "BASIC_AUTH_PASSWORD"
  ].all? { |var| ENV.keys.include?(var) }
end

raise "Missing ENV vars" unless env_vars_present?

enable :logging

use Rack::Protection, except: [:remote_token]

run Sinatra::Application
