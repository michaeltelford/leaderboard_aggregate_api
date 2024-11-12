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
  html = request.accept?("text/html")
  jumps = build_jumps_response(html:)

  [200, CONTENT_TYPE_HTML, jumps]
end

### Private helper methods ###

# Returns an object that responds to #each and yields only strings to the given block
def build_jumps_response(html: true)
  json_str = File.read(OUTPUT_FILE_PATH)
  jumps = JSON.parse(json_str, symbolize_names: true)

  jumps_to_s(jumps, html:)
end
