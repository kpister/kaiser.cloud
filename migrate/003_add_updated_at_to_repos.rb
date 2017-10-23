Sequel.migration do
    change do
        add_column :repos, :updated_at, DateTime
        add_column :repos, :authors, String
    end
end
