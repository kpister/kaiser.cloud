Sequel.migration do
    change do
        add_column :commits, :author, String 
    end
end
