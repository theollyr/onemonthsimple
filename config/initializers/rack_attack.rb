class Rack::Attack
  # Throttle all requests by IP (60 rpm)
  throttle('req/ip', limit: 300, period: 5.minutes, &:ip)

  # Throttle login requests by IP (5 reqs per 20 secs)
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == '/sessions' && req.post?
  end
end
