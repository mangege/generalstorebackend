Sequel.migration do
  change do
    create_table :users do
      primary_key :id, type: :Bignum
      String :uuid, size: 36, unique: true
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :taobao_categories do
      primary_key :id, type: :Bignum
      String :name, unique: true
      Integer :position
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :taobao_shops do
      primary_key :id, type: :Bignum
      String :title
      Bignum :shop_id, unique: true
      Integer :kind # 0表示集市，1表示商城
      TrueClass :flagship
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :taobao_items do
      primary_key :id, type: :Bignum
      String :title
      Bignum :item_id, unique: true
      Bignum :category_id
      Bignum :shop_id
      BigDecimal :coupon_amount, size: [10, 2] # 70, 为0则表示没有优惠券
      BigDecimal :coupon_start_fee, size: [10, 2] # 212.00
      BigDecimal :price, size: [10, 2] # 最终价
      BigDecimal :orig_price, size: [10, 2] # 原价
      Integer :coupon_total_count # 优惠券总量
      Integer :coupon_remain_count # 优惠券剩余量
      DateTime :coupon_start_time # 1572019200000
      DateTime :coupon_end_time # 1572019200000
      Integer :volume # 30天销量
      String :pict_url, size: 1024
      String :click_url, size: 1024 # 推广链接,有优惠券时推广链接有些默认不会展示优惠券
      String :click_word # 推广口令
      String :coupon_url, size: 1024 # 宝贝+券二合一页面链接
      String :coupon_word # 宝贝+券二合一页面口令
      BigDecimal :presale_deposit, size: [10, 2] # 预售定金
      BigDecimal :presale_discount_fee, size: [10, 2] # 预售优惠,不一定会有
      String :presale_discount_fee_text # 预售商品-优惠信息, 不一定有,没有的话则付定金没优惠, 付定金立减5元

      String :material_kind
      Integer :kind # 1 普通, 2 优惠券, 3 预售
      Integer :step # 0 完成, 1 待抓取店铺, 2 待抓取口令
      TrueClass :available

      DateTime :created_at
      DateTime :updated_at
    end
  end
end
