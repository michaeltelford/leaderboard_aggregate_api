require "dotenv"
require_relative "./aggregate"

Dotenv.load

task default: :serve

desc "Start the API locally"
task :serve do
  system "bundle exec rackup -s Puma -p #{ENV["PORT"]}"
end

desc "Aggregate the leaderboard results"
task :aggregate do
  aggregate_results
end

desc "Start an infinite aggregate loop"
task :aggregate_loop do
  aggregate_loop
end

desc "Build a production docker image"
task build_image: [:aggregate] do
  system "docker build -t laa:latest ."
end

desc "Run the API in a production docker container"
task :run_image do
  port = ENV["PORT"]
  system "docker run --rm -it --env-file .env -p #{port}:#{port} laa:latest"
end
