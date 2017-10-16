if CFG[:dev]
    database = "myapp_development"
    user     = CFG[:pguser]
    password = CFG[:pgpassword]
    DB = Sequel.connect(adapter: "postgres", database: database, host: "127.0.0.1", user: user, password: password)
else 
    #DB = Sequel.connect(ENV['DATABASE_URL'])
end