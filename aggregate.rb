#!/bin/ruby
#
# Script to retrieve and aggregate the results/jumps from all leaderboards.
# The output is a common jump format stored in a file called `aggregated.json`.
#

require "net/http"
require "json"
require "bigdecimal"
require "bigdecimal/util"

OUTPUT_FILE_PATH = "./public/aggregated_results.json".freeze

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

  JSON.parse(resp.body, symbolize_names: true)
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
    height = result[:value].to_d.truncate(1).to_f

    jumps << {
      source: "Surfr",
      name: result[:user][:name],
      height:,
      country: result[:user][:countryIOC],
    }
  end

  woo_results.each do |result|
    image_url = result[:_pictures].
      select { |pic| pic[:type] == "user" }.
      first&.[](:url)

    jumps << {
      source: "Woo",
      name: "#{result[:name]} #{result[:lastname]}",
      height: result[:score],
      image_url:,
    }
  end

  puts "Successfully mapped and sorted #{jumps.size} jump result(s)"

  # Sorted desc i.e. highest jump first aka jumps[0]
  jumps = jumps.sort_by { |jump| -jump[:height] }

  # Add the :position field to each sorted jump
  jumps.each_with_index.map do |jump, i|
    jump[:position] = i + 1
    jump
  end
end

def write_jumps_to_file(jumps)
  File.open(OUTPUT_FILE_PATH, "w") { |f| f.write(jumps.to_json) }

  puts "Results written to file: #{OUTPUT_FILE_PATH}"
end

def jumps_to_s(jumps, html: false)
  line_break = html ? "<br>" : "\n"

  jumps.map do |j|
    "#{j[:position]}. #{j[:source]} - #{j[:name]} --> #{j[:height]}#{line_break}"
  end
end

def aggregate_results
  puts "Running aggregate script on #{Time.now.utc}"

  surfr_results, woo_results = pull_sources
  jumps = map_and_sort_results(surfr_results, woo_results[:items])
  write_jumps_to_file(jumps)

  puts "\nTop 10 highest jumps:"
  jumps_to_s(jumps).first(10).each { |str| puts str }
  puts "\nFinished aggregate script"
end

if __FILE__ == $0
  aggregate_results
end
