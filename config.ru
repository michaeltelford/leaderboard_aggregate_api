require './api'

enable :logging, :static

configure :production do
  disable :logging
end

run Sinatra::Application
