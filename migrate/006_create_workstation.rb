Sequel.migration do
    change do
        create_table(:workstations) do
            primary_key :id, unique: true
            String :tape, null: false
            String :history, null: false
            Integer :instruction_ptr
            Integer :data_ptr
        end
    end
end
