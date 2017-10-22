require 'roda'
require_relative 'models'
require_relative 'helpers/github_connector.rb'

class Cloud < Roda
    opts[:root] = File.dirname(__FILE__)
    plugin :render
    plugin :head
    plugin :public

    route do |r|
        r.public 
        @info ||= get_git_info

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
                @readme = add_readme(project)
                view('project')
            end
        end

        # My post requests
    end
end
