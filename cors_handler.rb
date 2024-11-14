# Add the necesssary CORS related headers to all API responses
class CORSHandler
  def initialize(app, origin:)
    @app = app
    @origin = origin

    raise "Origin must be set" if @origin.empty?
  end

  def call(env)
    # For all requests
    cors_headers = {
      "access-control-allow-origin" => @origin,
      "vary" => "Origin"
    }

    # For pre-flight only requests
    if env["REQUEST_METHOD"] == "OPTIONS"
      cors_headers["access-control-allow-methods"] = "POST,PUT,PATCH,DELETE"
      cors_headers["access-control-allow-headers"] = "Content-Type,Authorization"
      cors_headers["access-control-max-age"] = "86400" # 24 hours

      return [200, cors_headers, [""]]
    end

    status, headers, body = @app.call(env)
    response_headers = cors_headers.merge(headers)

    [status, response_headers, body]
  end
end
