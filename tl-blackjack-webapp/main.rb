require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => '123456'

get '/' do
  erb :index
end

get'/test' do
  "From testing action"
end
