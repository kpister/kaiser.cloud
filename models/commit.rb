
class Commit < Sequel::Model(DB[:commits])
    attr_accessor :message, :created_at, :sha, :repo_id, :author
end
