require "sinatra"
require "base64"

require "sinatra/reloader" if development?
require "byebug" if development?

require_relative "aggregate"


get "/health" do
  200
end

post "/aggregate" do
  halt 401 unless authorized?(request.env)

  aggregate_results
  201
end

get "/" do
  last_modified results_last_modified

  @delay = ENV["AGGREGATE_RESULTS_HOURS_DELAY"].to_i
  @jumps = read_jumps_from_file

  top_surfr_index     = first_source_index(@jumps, "surfr")
  top_woo_index       = first_source_index(@jumps, "woo")
  @top_result_indexes = [top_surfr_index, top_woo_index]

  erb :index
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

# Return the array index of the first result with matching source.
def first_source_index(jumps, source)
  jumps.index { |jump| jump[:source].to_s.downcase == source.to_s.downcase }
end
