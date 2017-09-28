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
            @info = get_git_info
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

def call_url(url)
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    response.code == "200" ? JSON.parse(response.body) : "error"
end

def get_git_info
    # Get commit info -- this is only the most recent 30 events. need to grab more pages or table
    commits_body = call_url('https://api.github.com/users/kpister/events')
    commit_count = 0
    commit_messages = []
    commits_body.each do |event|
        if event['payload'] && event['payload']['commits']
            commits = event['payload']['commits']
            commits.reverse.each do |commit|
                commit_count += 1
                commit_messages << commit['message']
            end
        end
    end

    # Get repo info
    repo_body = call_url('https://api.github.com/users/kpister/repos')
    star_count = 0
    repo_count = 0
    primary_languages_used = []
    repo_body.each do |repo|
        if repo['stargazers_count'] > 0
            star_count += repo['stargazers_count']
            repo_count += 1
            primary_languages_used << repo['language']
        end
    end

    {
        commit_count: commit_count, 
        commit_messages: commit_messages, 
        star_count: star_count, 
        repo_count: repo_count, 
        primary_languages_used: primary_languages_used.uniq.sort
    }
end
