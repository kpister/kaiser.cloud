require "roda"

class App < Roda
    plugin :static, ["/images", "/css", "/js"]
    plugin :render
    plugin :head

    route do |r|
        r.root do
            view("homepage")
        end

        r.get do
            r.is "about" do
                view("about")
            end
            
            r.is "contact" do
                view("contact")
            end

            r.is "resume" do
                r.redirect "https://bit.ly/2xjjXs4"
            end

            r.is "math", Integer, Integer do |a, b|
                "#{a + b}"
            end

        end
    end
end
