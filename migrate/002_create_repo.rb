Sequel.migration do
    change do
        create_table(:repos) do
            primary_key :id, unique: true
            String :name, null: false
            String :languages
            Integer :stars
            String :readme
        end
    end
end
