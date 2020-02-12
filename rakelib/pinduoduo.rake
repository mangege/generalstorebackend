require './lib/pinduoduoclient'
require './lib/models'


class PinduoduoJinbaoTask
  def run
    clean_items
    fetch_top_list
    fetch_recommend_goods
    fetch_shop_info
    generate_url
  end

  private
  def clean_items
    last_id = 0
    while true
      items = PinduoduoItem.where(available: true).where{ id > last_id }.limit(100)
      break if items.empty?
      DB.transaction do
        items.each do |item|
          last_id = item.id
          item.update_available
          item.save
        end
      end
    end
  end

  def fetch_top_list
    # 1-实时热销榜；2-实时收益榜
    fetch_top_list_by_sort_type(1, '实时热销')
    fetch_top_list_by_sort_type(2, '实时推荐')
    # 今日销量榜 https://jinbao.pinduoduo.com/promotion/hot-promotion
    fetch_top_list_by_sort_type(3, '今日热销')
  end

  def fetch_top_list_by_sort_type(sort_type, material_kind)
    max_limit = 600
    offset = 0
    while true
      params = {sort_type: sort_type, limit: max_limit, offset: offset}
      resp = PinduoduoClinet.top_goods(params)
      # FIXME check resp error
      save_goods_list(resp['top_goods_list_get_response']['list'], material_kind)
      offset += max_limit
      break if offset >= resp['top_goods_list_get_response']['total']
    end
  end

  def save_goods_list(goods_list, material_kind)
    goods_list.each do |goods_item|
      find_or_save_goods(goods_item, material_kind)
    end
  end

  def find_or_save_goods(goods_item, material_kind)
    return if !goods_item['has_coupon'] # 无优惠券不添加

    mall = nil
    if goods_item['mall_id']
      mall = find_or_save_mall(goods_item)
    end
    goods = PinduoduoItem.first(item_id: goods_item['goods_id'])
    goods = PinduoduoItem.new(item_id: goods_item['goods_id']) if goods.nil?
    if mall && goods.fetch_shop_at.nil?
      goods.shop_id = mall.id
      goods.fetch_shop_at = Time.now
    end

    volume = goods_item['sales_tip'].gsub('+', '')
    if volume.include?('万')
      volume = volume[/(\d+\.?\d?)/].to_f * 10000
    end

    goods.set(
      title: goods_item['goods_name'],
      pict_url: goods_item['goods_image_url'],
      material_kind: material_kind,
      volume: volume,
    )

    goods.set(
      coupon_amount: goods_item['coupon_discount'].to_f / 100,
      coupon_start_fee: goods_item['coupon_min_order_amount'].to_f / 100,
      normal_price: goods_item['min_normal_price'].to_f / 100,
      group_price: goods_item['min_group_price'].to_f / 100,
      coupon_total_count: goods_item['coupon_total_quantity'],
      coupon_remain_count: goods_item['coupon_remain_quantity'],
      coupon_start_time: Time.at(goods_item['coupon_start_time']),
      coupon_end_time: Time.at(goods_item['coupon_end_time']),
    )

    goods.update_available
    goods.save
    goods
  end

  def find_or_save_mall(mall_item)
    mall = PinduoduoShop.first(shop_id: mall_item['mall_id'])
    return mall if mall

    # FIXME kind 0, 未知
    mall = PinduoduoShop.new(shop_id: mall_item['mall_id'], title: mall_item['mall_name'], kind: 0)
    mall.save
    mall
  end

  def fetch_recommend_goods
    
  end

  def generate_url
    
  end
end

task :test_goods_recommend do
  params = {limit: 400}
  puts PinduoduoClinet.goods_recommend(params)
end

task :fetch_ddk do
  PinduoduoJinbaoTask.new.run
end
