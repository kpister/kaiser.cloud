require 'sequel'

if ENV['RACK_ENV'] == 'development'
    database = "cloud_dev"
    user     = ENV['USER']
    password = ""
    DB = Sequel.connect(adapter: "postgres", database: database, host: "127.0.0.1", user: user, password: password)
else 
    DB = Sequel.connect(ENV['DATABASE_URL'])
end
