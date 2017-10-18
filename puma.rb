require 'sequel'
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 9292
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
    # connect to database?
    Sequel.extension :connection_validator
    Sequel.pool.connection_validation_timeout = -1
end