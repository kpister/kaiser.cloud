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
            return true 
        end
    end
    return false
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
            exists = prevent_repeat(db_repos, :id, repo['id'])

            # update languages, authors and commits
            readme = call_url("https://api.github.com/repos/kpister/#{repo['name']}/readme", true)
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
                authors << contributor["login"] if contributor['contributions'].to_f / commits.count > 0.25
            end

            readme_pieces = parse_readme(readme)
            if exists
                db_repos.where(id: repo['id']).update(languages: languages.keys.to_s.tr('[]"', ''))
                db_repos.where(id: repo['id']).update(authors: authors.to_s.tr('[]"', ''))
                db_repos.where(id: repo['id']).update(stars: repo['stargazers_count'])
                db_repos.where(id: repo['id']).update(name: repo['name'])
                db_repos.where(id: repo['id']).update(desc: readme_pieces[0])
                db_repos.where(id: repo['id']).update(todo: readme_pieces[1])
                db_repos.where(id: repo['id']).update(tags: readme_pieces[2])
            else
                db_repos.insert(id: repo['id'], 
                                name: repo['name'], 
                                languages: languages.keys.to_s.tr('[]"', ''),
                                stars: repo['stargazers_count'],
                                authors: authors.to_s.tr('[]"', ''),
                                desc: readme_pieces[0],
                                todo: readme_pieces[1],
                                tags: read_pieces[2])
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
        repo_names: db_repos.map(:name).sort_by{ |rn| rn.downcase },
    }
end

def parse_readme(readme)
    text = Hash.new
    current = ""
    first = ""
    readme.each_line do |line|
        if line[0] == "#"
            current = line.strip.tr('#', '').tr(' ', '').downcase
            if first == ""
                first = current
            end
            text[current] = ""
        else
            if text[current]
                text[current] += line
            else
                text[current] = line
            end
        end
    end
    return text[first], text['todo'], text['tags']
end