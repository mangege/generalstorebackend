Sequel.migration do
  change do
    alter_table(:taobao_items) do
      add_index :volume
    end

    alter_table(:pinduoduo_items) do
      add_index :volume
    end
  end
end
