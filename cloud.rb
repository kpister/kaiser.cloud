require 'roda'
require 'net/http'
require 'uri'
require 'json'

class Cloud < Roda
    opts[:root] = File.dirname(__FILE__)
    plugin :render
    plugin :head
    plugin :public

    route do |r|
        r.public 

        r.root do
            uri = URI.parse('https://api.github.com/users/kpister/events')
            response = Net::HTTP.get_response(uri)
            body = response.code == "200" ? JSON.parse(response.body) : "error"
            @commit_count = 0
            @commit_messages = []
            body.each do |event|
                if event['payload'] && event['payload']['commits']
                    commits = event['payload']['commits']
                    commits.each do |commit|
                        @commit_count += 1
                        @commit_messages << commit['message']
                    end
                end
            end
            view('homepage')
        end

        # My get requests
        r.get do
            r.is 'resume' do
                r.redirect 'https://bit.ly/2xjjXs4'
            end

            r.is 'github' do
                r.redirect 'https://github.com/kpister'
            end

            r.is 'bitbucket' do
                r.redirect 'https://bitbucket.org/kpister'
            end

            r.is 'math', Integer, Integer do |a, b|
                "#{a + b}"
            end

        end

        # My post requests
    end
end
