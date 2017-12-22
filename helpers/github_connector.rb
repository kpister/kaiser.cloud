require 'net/http'
require 'uri'
require 'json'
require 'time'
require 'sequel'
require_relative '../db'

def call_url(url, raw=false)
    uri = URI.parse(url)
    response = ""
    if raw
        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/vnd.github.v3.raw+json"
        
        req_options = {
          use_ssl: uri.scheme == "https",
        }
        
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
        return response.body if response.code == "200"
    else 
        response = Net::HTTP.get_response(uri)
        return JSON.parse(response.body) if response.code == "200"
    end
    puts response.body.to_s
    return "error"
end

def prevent_repeat(hash, key, item)
    hash.each do |record|
        if record[key.to_sym] == item
            return true 
        end
    end
    return false
end

def update_readme(db_repos, repo)
    readme = parse_readme(call_url("https://api.github.com/repos/kpister/#{repo['name']}/readme", true))
    if readme == 'error'
        puts "Readme error encountered"
        return
    end

    db_repos.where(id: repo['id']).update(desc: readme[:desc])
    db_repos.where(id: repo['id']).update(todo: readme[:todo])
    db_repos.where(id: repo['id']).update(tags: readme[:tags])
end

def update_authors(db_repos, repo, commit_count)
    contributors = call_url("https://api.github.com/repos/kpister/#{repo['name']}/contributors")
    if contributors == 'error'
        puts "Authors error encountered"
        return
    end

    authors = []
    contributors.each do |contributor|
        authors << contributor["login"] if contributor['contributions'].to_f / commit_count > 0.25
    end
    db_repos.where(id: repo['id']).update(authors: authors.to_s.tr('[]"', ''))
end 

def update_languages(db_repos, repo)
    languages = call_url("https://api.github.com/repos/kpister/#{repo['name']}/languages")
    if languages == 'error'
        puts "Languages error encountered"
        return
    end
    db_repos.where(id: repo['id']).update(languages: languages.keys.to_s.tr('[]"', ''))
end

def update_commits(db_commits, repo)
    commits = call_url("https://api.github.com/repos/kpister/#{repo['name']}/commits")
    if commits == 'error'
        puts "Commits error encountered"
        return
    end
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
    return commits.count
end


def update_repo_info(readme=true, authors=true, languages=true, commits=true)
    db_repos = DB[:repos]
    db_commits = DB[:commits]

    repo_body = call_url('https://api.github.com/users/kpister/repos')
    if repo_body == 'error'
        puts "Repo error encountered"
        return
    end

    # for every repo...
    repo_body.each do |repo|
        # ... that I have starred
        if repo['stargazers_count'] > 0
            # check if it exists already
            exists = prevent_repeat(db_repos, :id, repo['id'])
            if !exists
                db_repos.insert(id: repo['id'], 
                                name: repo['name'], 
                                stars: repo['stargazers_count'])
            else
                db_repos.where(id: repo['id']).update(stars: repo['stargazers_count'])
                db_repos.where(id: repo['id']).update(name: repo['name'])
            end

            # update languages, authors and commits
            update_readme(db_repos, repo) if readme
            commit_count = update_commits(db_commits, repo) if commits
            update_authors(db_repos, repo, commit_count) if authors
            update_languages(db_repos, repo) if languages
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
    {
        desc: parse_desc(text[first]), 
        todo: parse_todo(text['todo']),
        tags: parse_tags(text['tags']),
    }
end

def parse_desc(desc)
    return desc
end

def parse_todo(todo)
    if todo
        return todo.gsub(/\* - /, "\n").gsub(/\[x\]/, "x:").gsub(/\[ \]/, "_:")
    else
        return "Project is finished for now"
    end
end

def parse_tags(tags)
    if tags
        return tags.strip
    else
        return "notags"
    end
end