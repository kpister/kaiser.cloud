# Migrate

migrate = lambda do |version|
    require_relative 'db'
    require 'logger'
    Sequel.extension :migration
    DB.loggers << Logger.new($stdout)
    Sequel::Migrator.apply(DB, 'migrate', version)
end

namespace :migrate do
desc "Migrate up"
    task :up do
        migrate.call(nil)
    end
    desc "Migrate down"
    task :down do
        migrate.call(0)
    end
end

desc "Migrate up"
task :migrate => "migrate:up"
