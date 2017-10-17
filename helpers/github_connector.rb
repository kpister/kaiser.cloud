require 'net/http'
require 'uri'
require 'json'
require 'time'
require 'sequel'

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

def prevent_repeat(hash, key, item)
    hash.each do |inner_hash|
        if inner_hash[key.to_sym] == item
            return false
        end
    end
    return true
end

def update_git_info
    db_commits = DB[:commits]
    commits_body = call_url('https://api.github.com/users/kpister/events')
    commits_body&.each do |event|
        if event['payload'] && event['payload']['commits']
            event['payload']['commits'].reverse.each do |commit|
                if prevent_repeat(db_commits_all, 'sha', commit['sha'])
                    db_commits.insert(message: commit['message'], 
                                created_at: Time.parse(event['created_at']), 
                                sha: commit['sha'], 
                                repo_id: event['repo']['id'])
                end
            end
        end
    end
end


def get_git_info
    # Get commit info -- this is only the most recent 30 events. need to grab more pages or table
    commit_messages = []
    db_commits = DB[:commits]
    db_commits.each do |commit|
        commit_messages << commit[:message]
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
            primary_languages_used << repo['language'] if repo['language']
            repo_names << repo['name'] if repo['name']
        end
    end

    {
        commit_count: db_commits.count, 
        commit_messages: commit_messages, 
        star_count: star_count, 
        repo_count: repo_count, 
        primary_languages_used: primary_languages_used.uniq.sort,
        repo_names: repo_names
    }
end
