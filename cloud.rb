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
        @info ||= get_git_info
        r.public 

        r.root do
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

            r.is "gprojects", String do |project|
                @readme_body = call_url("https://api.github.com/repos/kpister/#{project}/readme", true)
                view('project')
            end



        end

        # My post requests
    end
end

def call_url(url, raw=false)
    uri = URI.parse(url)
    respones = ""
    if raw
        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/vnd.github.v3.raw+json"
        
        req_options = {
          use_ssl: uri.scheme == "https",
        }
        
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
        response.code == "200" ? response.body : ["error"]
    else 
        response = Net::HTTP.get_response(uri)
        response.code == "200" ? JSON.parse(response.body) : ["error"]
    end
end

def get_git_info
    # Get commit info -- this is only the most recent 30 events. need to grab more pages or table
    commits_body = call_url('https://api.github.com/users/kpister/events')
    commit_count = 0
    commit_messages = []
    commits_body&.each do |event|
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
    repo_names = []
    primary_languages_used = []
    repo_body.each do |repo|
        if repo['stargazers_count'] > 0
            star_count += repo['stargazers_count']
            repo_count += 1
            primary_languages_used << repo['language']
            repo_names << repo['name']
        end
    end

    {
        commit_count: commit_count, 
        commit_messages: commit_messages, 
        star_count: star_count, 
        repo_count: repo_count, 
        primary_languages_used: primary_languages_used.uniq.sort,
        repo_names: repo_names
    }
end
