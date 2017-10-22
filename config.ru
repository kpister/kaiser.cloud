dev = ENV['RACK_ENV'] == 'development'

require 'rack/unreloader'
Unreloader = Rack::Unreloader.new(:subclasses=>%w'Roda Sequel::Model', :reload=>dev){Cloud}
require 'roda'
require_relative 'models'
Unreloader.require('cloud.rb'){'Cloud'}
run(dev ? Unreloader : Cloud.freeze.app)
