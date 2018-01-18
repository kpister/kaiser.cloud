require 'roda'
require_relative 'models'
require_relative 'helpers/github_connector.rb'
require_relative 'helpers/webprime.rb'

class Cloud < Roda
    opts[:root] = File.dirname(__FILE__)
    plugin :render
    plugin :head
    plugin :public
    plugin :static ['/images'], root: 'public'

    route do |r|
        r.public 
        @info ||= get_git_info
        @author = 'Kaiser'
        @languages = 'Go, Ruby, C++'

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

            r.on 'ws' do
                r.is do
                    db_ws = DB[:workstations]
                    @ws = db_ws.insert(tape: '0', history: '', 
                                    instruction_ptr: 0,
                                    data_ptr: 0)
                    puts @ws
                    view('welcome')
                end

                r.is Integer do |id|
                    @ws = DB[:workstations].where(id: id).first
                    view('workstation')
                end

                r.is Integer, String do |id, command|
                    #Remove command / Undo command
                    #Rerun code
                    @ws = DB[:workstations].where(id: id).first
                    @ws, @error = handle_command(@ws, command)
                    DB[:workstations].where(id: id).update(instruction_ptr: @ws[:instruction_ptr],
                                                        data_ptr: @ws[:data_ptr], tape: @ws[:tape], history: @ws[:history])
                    view('workstation')
                end
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