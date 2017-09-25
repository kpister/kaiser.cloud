require "roda"

class App < Roda
    opts[:root] = File.dirname(__FILE__)
    plugin :render
    plugin :head
    plugin :public

    route do |r|
        r.public 

        r.root do
            view("homepage")
        end

        # My get requests
        r.get do
            r.is "resume" do
                r.redirect "https://bit.ly/2xjjXs4"
            end

            r.is "github" do
                r.redirect "https://github.com/kpister"
            end

            r.is "bitbucket" do
                r.redirect "https://bitbucket.org/kpister"
            end

            r.is "math", Integer, Integer do |a, b|
                "#{a + b}"
            end

        end

        # My post requests
    end
end
