require 'bundler'
Bundler.require(:default)

# middleware
use Rack::Session::Cookie, :secret => SecureRandom.hex(32)

require File.expand_path('../app', __FILE__)

run App
