#!/bin/ruby
#
# Script to retrieve and aggregate the results/jumps from all leaderboards.
# The output is a common jump format stored in a file called `aggregated.json`.
#

require "net/http"
require "json"

OUTPUT_FILE_PATH = "./aggregated_results.json".freeze

def sources
  [
    {
      name: "Surfr",
      url: "https://kiter-271715.appspot.com/leaderboards/list/height/alltime/0?accesstoken=e16a0f15-67c5-4306-81a5-0c554a55a222",
    },
    {
      name: "Woo",
      url: "https://prod3.apiwoo.com/leaderboardsHashtags?offset=0&page_size=50&feature=height&game_type=big_air",
    }
  ]
end

def make_http_request(source_name, url)
  puts "Requesting results from #{source_name}..."

  uri = URI(url)
  resp = Net::HTTP.get_response(uri)
  success = resp.code == "200"

  puts "HTTP status: #{resp.code} (#{source_name})"
  raise "Non successful HTTP response (#{source}): #{resp.body}" unless success

  JSON.parse(resp.body)
rescue RuntimeError => e
  # Returns nil if an error is raised
  puts "Failed making HTTP request (#{source_name}): #{e}"
end

def pull_sources
  threads = sources.map do |source|
    Thread.new { make_http_request(source[:name], source[:url]) }
  end

  results = threads.map(&:value) # wait for all threads to return responses
  raise "Error occurred pulling sources" if results.any?(&:nil?)

  results
end

def map_and_sort_results(surfr_results, woo_results)
  jumps = []

  surfr_results.each do |result|
    jumps << {
      source: "Surfr",
      name: result["user"]["name"],
      height: result["value"],
      country: result["user"]["countryIOC"],
    }
  end

  woo_results.each do |result|
    image_url = result["_pictures"].
      select { |pic| pic["type"] == "user" }.
      first&.[]("url")

    jumps << {
      source: "Woo",
      name: "#{result["name"]} #{result["lastname"]}",
      height: result["score"],
      image_url:,
    }
  end

  puts "Successfully mapped and sorted #{jumps.size} jump result(s)"

  # Sorted desc i.e. highest jump first aka jumps[0]
  jumps.sort_by { |jump| -jump[:height] }
end

def write_jumps_to_file(jumps)
  File.open(OUTPUT_FILE_PATH, "w") { |f| f.write(JSON.pretty_generate(jumps)) }

  puts "Results written to file: #{OUTPUT_FILE_PATH}"
end

def main
  puts "Running aggregate script on #{Time.now.utc}"

  surfr_results, woo_results = pull_sources
  jumps = map_and_sort_results(surfr_results, woo_results["items"])
  write_jumps_to_file(jumps)

  puts "\nTop 10 highest jumps:"
  jumps.first(10).each { |j| puts "#{j[:source]} - #{j[:name]} --> #{j[:height]}" }
  puts "\nFinished aggregate script"
end

main
