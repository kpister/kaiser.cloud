require "roda"

class App < Roda
    plugin :static, ["/images", "/css", "/js"]
    plugin :render
    plugin :head

    route do |r|
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
