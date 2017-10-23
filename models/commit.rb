
class Commit < Sequel::Model(DB[:commits])
    attr_accessor :message, :created_at, :sha, :repo_id, :author

    def get_date
        Date::ABBR_MONTHNAMES[created_at.month]+"-"+created_at.day.to_s if created_at
        
    end
end
