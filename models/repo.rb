
class Repo < Sequel::Model
    attr_accessor :name, :stars, :languages, :readme, :authors
end