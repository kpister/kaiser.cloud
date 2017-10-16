Sequel.migration do
    change do
        create_table(:commits) do
            primary_key :id, unique: true
            String :message, null: false
            DateTime :created_at
            String :sha, null: false
            Integer :repo_id, null: false
        end
    end
end
