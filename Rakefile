# Migrate
require_relative 'helpers/github_connector.rb'

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
    desc "Bounce migrations"
    task :bounce do
        migrate.call(0)
        migrate.call(nil)
    end
end

desc "Migrate up"
task :migrate => "migrate:up"

namespace :update do
    namespace :github do
        desc "Update github repos"
        task :all do
            update_repo_info
        end

        desc "Update github repos readmes"
        task :readme do
            update_repo_info(readme: true)
        end

        desc "Update github repos languages"
        task :languages do
            update_repo_info(languages: true)
        end

        desc "Update github repos authors"
        task :authors do
            update_repo_info(authors: true)
        end

        desc "Update github repos commits"
        task :commits do
            update_repo_info(commits: true)
        end

        desc "Get old github repo commits"
        task :old do
            update_repo_info(old: true)
        end
    end
end

desc "Update"
task :update => "update:github:all"