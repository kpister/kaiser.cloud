require 'net/http'
require 'uri'
require 'json'
require 'time'
require 'sequel'
require_relative '../db'

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

def add_readme(project)
    # implement logic to check if I need to make a pull -- via recent commits/time
    # only store description, authors, todo
    readme = call_url("https://api.github.com/repos/kpister/#{project}/readme", true)
    DB[:repos].where(name: project).update(readme: readme)
    return readme
end

def update_commit_info
    db_commits = DB[:commits]
    commits_body = call_url('https://api.github.com/users/kpister/events')
    commits_body&.each do |event|
        if event['payload'] && event['payload']['commits']
            event['payload']['commits'].reverse.each do |commit|
                if prevent_repeat(db_commits, 'sha', commit['sha'])
                    db_commits.insert(message: commit['message'], 
                                created_at: Time.parse(event['created_at']), 
                                sha: commit['sha'], 
                                repo_id: event['repo']['id'])
                end
            end
        end
    end
end

def update_repo_info
    db_repos = DB[:repos]
    repo_body = call_url('https://api.github.com/users/kpister/repos')
    repo_body.each do |repo|
        if repo['stargazers_count'] > 0 && prevent_repeat(db_repos, 'id', repo['id'])
            db_repos.insert(id: repo['id'], 
                            name: repo['name'], 
                            languages: repo['language'], 
                            stars: repo['stargazers_count'])
        end
    end
end

def get_git_info
    # Get commit info -- this is only the most recent 30 events. need to grab more pages or table
    db_commits = DB[:commits]
    # Get repo info
    db_repos = DB[:repos]
    primary_languages_used = []
    db_repos.each do |repo|
        # TODO: parse languages if it is is multiple
        primary_languages_used << repo[:languages] if repo[:languages]
    end

    {
        commit_count: db_commits.count, 
        commit_messages: db_commits.order(:created_at).map(:message).reverse,
        star_count: db_repos.sum(:stars), 
        repo_count: db_repos.count, 
        primary_languages_used: primary_languages_used.uniq.sort,
        repo_names: db_repos.map(:name)
    }
end
