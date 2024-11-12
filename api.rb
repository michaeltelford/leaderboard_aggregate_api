require 'sinatra'
require 'byebug'
require_relative 'aggregate'

CONTENT_TYPE_JSON = { "Content-Type" => "application/json" }.freeze
CONTENT_TYPE_HTML = { "Content-Type" => "text/html; charset=utf-8" }.freeze

get '/health' do
  200
end

post '/aggregate' do
  # TODO: Require basic auth here or return 401
  aggregate_results

  201
end

get '/' do
  jumps = build_jump_response

  [200, CONTENT_TYPE_HTML, jumps]
end

### Private helper methods ###

# Returns an object that responds to #each and yields only strings to the given block
def build_jump_response
  json_str = File.read(OUTPUT_FILE_PATH)
  jumps = JSON.parse(json_str, symbolize_names: true)

  jumps.map { |j| "#{j[:source]} - #{j[:name]} --> #{j[:height]}\n" }
end
