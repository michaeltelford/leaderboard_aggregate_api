require "sinatra"
require "base64"
require_relative "aggregate"

# NOTE: Comment out require "byebug" or docker build will fail
# require "byebug"

CONTENT_TYPE_JSON = { "Content-Type" => "application/json" }.freeze
CONTENT_TYPE_HTML = { "Content-Type" => "text/html; charset=utf-8" }.freeze

get "/health" do
  200
end

post "/aggregate" do
  halt 401 unless authorized?(request.env)

  aggregate_results
  201
end

get "/aggregated_results.json" do
  last_modified File.mtime(OUTPUT_FILE_PATH)
  json_str = File.read(OUTPUT_FILE_PATH)

  [200, CONTENT_TYPE_JSON, json_str]
end

get "/" do
  last_modified File.mtime(OUTPUT_FILE_PATH)
  html = request.accept?("text/html")
  jumps = build_jumps_response(html:)

  [200, CONTENT_TYPE_HTML, jumps]
end

### Private helper methods ###

# Performs HTTP basic authentication, returning true if authorized.
def authorized?(headers)
  auth_header = headers["HTTP_AUTHORIZATION"]
  return false unless auth_header
  return false unless auth_header.include?("Basic ")

  auth_header = auth_header.gsub("Basic ", "")
  secret = Base64.decode64(auth_header)
  return false unless secret.include?(":")

  username, password = secret.split(":")
  username == ENV["BASIC_AUTH_USERNAME"] && password == ENV["BASIC_AUTH_PASSWORD"]
end

# Returns an object that responds to #each and yields only strings to the given block
def build_jumps_response(html: true)
  json_str = File.read(OUTPUT_FILE_PATH)
  jumps = JSON.parse(json_str, symbolize_names: true)

  jumps_to_s(jumps, html:)
end
