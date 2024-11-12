require './api'

def env_vars_present?
  [
    "AGGREGATE_RESULTS",
    "BASIC_AUTH_USERNAME",
    "BASIC_AUTH_PASSWORD"
  ].all? { |var| ENV.keys.include?(var) }
end

raise "Missing ENV vars" unless env_vars_present?

enable :logging, :static

configure :production do
  disable :logging
end

run Sinatra::Application
