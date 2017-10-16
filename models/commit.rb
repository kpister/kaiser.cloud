
class Commit < Sequel::Model
    attr_accessor :message, :created_at, :sha, :repo_id
end
