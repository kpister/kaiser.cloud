
class Repo < Sequel::Model
    attr_accessor :name, :stars, :languages, :authors, :updated_at, :todo, :desc, :tags
end