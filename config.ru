require 'rack/protection'
require_relative './api'

# Add any required ENV vars to this array
def env_vars_present?
  [
    "AGGREGATE_RESULTS",
    "AGGREGATE_RESULTS_HOURS_DELAY",
    "BASIC_AUTH_USERNAME",
    "BASIC_AUTH_PASSWORD"
  ].all? { |var| ENV.keys.include?(var) }
end

# Returns the number of seconds to sleep before aggregating results
def aggregate_thread_delay
  hours = ENV["AGGREGATE_RESULTS_HOURS_DELAY"].to_i
  hours * 60 * 60
end

def next_check_time
  Time.now.utc + aggregate_thread_delay
end

raise "Missing ENV vars" unless env_vars_present?

enable :logging
enable :static

use Rack::Protection

run Sinatra::Application

# Start a thread to periodically update the aggregated_results.json file
Thread.new do
  loop {
    puts "Next aggregate update check at: #{next_check_time}"
    sleep(aggregate_thread_delay)

    if ENV["AGGREGATE_RESULTS"] != "true"
      puts 'Skipping aggregate update as ENV["AGGREGATE_RESULTS"] is not "true"'
      next
    end

    aggregate_results # -> aggregated_results.json
  }
end
