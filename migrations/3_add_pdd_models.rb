Sequel.migration do
  change do
    create_table :pinduoduo_shops do
      primary_key :id, type: :Bignum
      String :title
      Bignum :shop_id, unique: true
      Integer :kind # 店铺类型，1-个人，2-企业，3-旗舰店，4-专卖店，5-专营店，6-普通店
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :pinduoduo_items do
      primary_key :id, type: :Bignum
      String :title
      Bignum :item_id, unique: true
      Bignum :shop_id
      BigDecimal :coupon_amount, size: [10, 2] # 70, 为0则表示没有优惠券
      BigDecimal :coupon_start_fee, size: [10, 2] # 212.00
      BigDecimal :normal_price, size: [10, 2] # 单买价格,单位为分
      BigDecimal :group_price, size: [10, 2] # 成团价格,单位为分
      Integer :coupon_total_count # 优惠券总量
      Integer :coupon_remain_count # 优惠券剩余量
      DateTime :coupon_start_time # 1572019200000
      DateTime :coupon_end_time # 1572019200000
      Integer :volume # 销量
      String :pict_url, size: 1024
      String :click_url, size: 1024 # url 推广长链接
      String :wechat_url, size: 1024 # page_path
      String :qq_url, size: 1024 # page_path

      String :material_kind
      DateTime :fetch_shop_at
      DateTime :fetch_url_at
      TrueClass :available

      DateTime :created_at
      DateTime :updated_at
    end

    create_table :user_pinduoduo_items do
      Bignum :user_id
      Bignum :pinduoduo_item_id
      DateTime :created_at

      primary_key [:user_id, :pinduoduo_item_id]
      index [:user_id, :pinduoduo_item_id]
    end
  end
end
