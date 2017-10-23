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
    hash.each do |record|
        if record[key.to_sym] == item
            return record
        end
    end
    return nil
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
                unless prevent_repeat(db_commits, 'sha', commit['sha'])
                    db_commits.insert(message: commit['message'], 
                                created_at: Time.parse(event['created_at']), 
                                sha: commit['sha'], 
                                repo_id: event['repo']['id'],
                                author: "Kaiser")
                end
            end
        end
    end
end

def update_repo_info
    db_repos = DB[:repos]
    db_commits = DB[:commits]

    repo_body = call_url('https://api.github.com/users/kpister/repos')

    # for every repo...
    repo_body.each do |repo|
        # ... that I have starred
        if repo['stargazers_count'] > 0
            # check if it exists already
            record = prevent_repeat(db_repos, 'id', repo['id'])

            # update languages, authors and commits
            languages = call_url("https://api.github.com/repos/kpister/#{repo['name']}/languages")
            contributors = call_url("https://api.github.com/repos/kpister/#{repo['name']}/contributors")
            commits = call_url("https://api.github.com/repos/kpister/#{repo['name']}/commits")
            commits.each do |commit|
                unless prevent_repeat(db_commits, 'sha', commit['sha'])
                    db_commits.insert(
                        message: commit['commit']['message'],
                        sha: commit['sha'],
                        repo_id: repo['id'],
                        created_at: commit['commit']['author']['date'],
                        author: commit['commit']['author']['name']
                    )
                end
            end

            authors = []
            contributors.each do |contributor|
                authors << contributor["login"] if contributor['contributions'] > 2
            end

            if record
                repo.update(languages: languages.keys.to_s)
                repo.update(authors: authors.to_s)
                repo.update(stars: repo['stargazers_count'])
                repo.update(updated_at: repo['pushed_at'])
            else
                db_repos.insert(id: repo['id'], 
                                name: repo['name'], 
                                languages: languages.keys.to_s.tr('[]"', ''),
                                stars: repo['stargazers_count'],
                                updated_at: repo['pushed_at'],
                                authors: authors.to_s.tr('[]"', ''))
            end
        end
    end
end

def get_git_info
    # Get commit info -- this is only the most recent 30 events. need to grab more pages or table
    db_commits = DB[:commits].order(:created_at).reverse
    # Get repo info
    db_repos = DB[:repos]

    {

        commits: db_commits,
        repos: db_repos,
        repo_names: db_repos.map(:name),
        latest_commit: "#{Date::ABBR_MONTHNAMES[db_commits.first[:created_at].month]}-#{db_commits.first[:created_at].day}"

    }
end
