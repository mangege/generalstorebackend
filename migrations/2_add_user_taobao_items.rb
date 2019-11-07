Sequel.migration do
  change do
    create_table :user_taobao_items do
      Bignum :user_id
      Bignum :taobao_item_id
      DateTime :created_at

      primary_key [:user_id, :taobao_item_id]
      index [:user_id, :taobao_item_id]
    end
  end
end
