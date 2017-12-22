Sequel.migration do
    change do
        add_column :repos, :desc, String 
        add_column :repos, :todo, String
        add_column :repos, :tags, String
    end
end