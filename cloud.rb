require 'roda'
require_relative 'models'
require_relative 'helpers/github_connector.rb'

class Cloud < Roda
    opts[:root] = File.dirname(__FILE__)
    plugin :render
    plugin :head
    plugin :public
    plugin :static ['/images'], root: 'public'
    plugin :header_matchers

    route do |r|
        r.public 
        @info ||= get_git_info
        @author = 'Kaiser'
        @languages = 'Go, Ruby, C++'

        puts env['HTTP_GO_TIME'] if env['HTTP_GO_TIME']

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
                @repo = DB[:repos].where(name: project).first
                @commits = DB[:commits].where(repo_id: @repo[:id]).order(:created_at).reverse
                view('project')
            end
        end

        # My post requests
    end

    def pretty_date(date)
        return "#{Date::ABBR_MONTHNAMES[date.month]}-#{date.day}"
    end
end