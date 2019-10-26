Sequel.migration do
  change do
    create_table :users do
      primary_key :id, type: :Bignum
      String :uuid, size: 36
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :taobao_categories do
      primary_key :id, type: :Bignum
      String :name
      Integer :position
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
