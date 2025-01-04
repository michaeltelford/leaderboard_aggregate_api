#!/bin/ruby
#
# Script to retrieve and aggregate the results/jumps from all leaderboards.
# The output is a common jump format stored in a JSON file.
#

require "net/http"
require "json"
require "bigdecimal"
require "bigdecimal/util"
require "base64"


RESULTS_FILEPATH = "./aggregated_results.json".freeze


def results_filepath
  RESULTS_FILEPATH
end

def results_last_modified
  File.mtime(results_filepath)
end

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
  ].freeze
end

def max_jumps_per_source
  max = ENV["MAX_JUMPS_PER_SOURCE"]
  max = 20 unless max

  max.to_i.freeze
end


def make_http_request(source_name, url)
  # TODO: In future, apply max_jumps_per_source to API request

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
  max_jumps = max_jumps_per_source
  jumps = []

  surfr_results.each_with_index do |result, i|
    break if i == max_jumps

    jumps << {
      source: "Surfr",
      name: result[:user][:name],
      height: truncate_n_decimal_places(result[:value]),
      country: result[:user][:countryIOC],
    }
  end

  woo_results.each_with_index do |result, i|
    break if i == max_jumps

    image_url = result[:_pictures].
      select { |pic| pic[:type] == "user" }.
      first&.[](:url)

    jumps << {
      source: "Woo",
      name: "#{result[:name]} #{result[:lastname]}",
      height: truncate_n_decimal_places(result[:score]),
      image_url:,
    }
  end

  puts "Successfully mapped and sorted #{jumps.size} total jump result(s)"

  # Sorted desc i.e. highest jump first aka jumps[0]
  jumps = jumps.sort_by { |jump| -jump[:height] }

  # Add the :position field to each sorted jump
  jumps.each_with_index.map do |jump, i|
    jump[:position] = i + 1
    jump
  end
end

# Truncate (don't round up/down) the height to 1 decimal place
def truncate_n_decimal_places(value, n_places = 1)
  value.to_d.truncate(n_places).to_f
end

def read_jumps_from_file
  json_str = File.read(results_filepath)
  JSON.parse(json_str, symbolize_names: true)
end

def write_jumps_to_file(jumps)
  File.open(results_filepath, "w") { |f| f.write(jumps.to_json) }

  puts "Results written to file on #{results_last_modified}: #{results_filepath}"
end

def jumps_to_s(jumps, html: false)
  line_break = html ? "<br>" : "\n"

  jumps.map do |j|
    "#{j[:position]}. #{j[:source]} - #{j[:name]} --> #{j[:height]}#{line_break}"
  end
end

def results_changed?(jumps)
  return true unless File.exist?(results_filepath)

  new_results = Base64.encode64(jumps.to_json)
  current_results = Base64.encode64(read_jumps_from_file().to_json)

  changed = new_results != current_results
  result = changed ? "have" : "haven't"
  puts "Results #{result} changed"

  changed
end

def aggregate_results
  puts "Running aggregate script at #{Time.now.utc}"

  surfr_results, woo_results = pull_sources
  jumps = map_and_sort_results(surfr_results, woo_results[:items])
  write_jumps_to_file(jumps) if results_changed?(jumps)

  puts "\nTop 5 combined highest jumps:"
  jumps_to_s(jumps).first(5).each { |str| puts str }
  puts "\nFinished aggregate script"
end

if __FILE__ == $0
  aggregate_results
end
