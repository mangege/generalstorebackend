require 'yaml'
require './lib/app_config'
require './lib/taobaoclient'
require './lib/models'

class TaobaoMaterialTask
  def run
    clean_items
    load_id_data
    process_id_data
    fetch_shop_info
    fetch_item_word
  end

  private
  def clean_items
    last_id = 0
    while True
      items = TaobaoItem.where(available: true).where{ id > last_id }.limit(100)
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

  def load_id_data
    @id_data = Psych.load_file("./data/taobao_material_ids.yaml")
    @taobao_categories = TaobaoCategory.all
  end

  def process_id_data
    @id_data['taobao_material_ids'].each do |material_set|
      next if material_set['disabled']
      material_set['kinds'].each do |material_obj|
        material_obj['ids'].each do |material_id_arr|
          fetch_id_data(material_set, material_obj, material_id_arr)
        end
      end
    end
  end

  def fetch_shop_info
    while true
      items = TaobaoItem.where(fetch_shop_at: nil).limit(40)
      break if items.empty?
      num_iids = items.select_map(:item_id)
      ret = TaobaoClinet.item_info(num_iids: num_iids.join(','))
      if TaobaoClinet.error_result?(ret)
        puts ret.inspect
        next
      end
      items.each do |item|
        item.fetch_shop_at = Time.now
        result = ret['results'].find{|a| a['num_iid'] == item.item_id}
        if result
          shop = find_or_save_shop(result)
          item.shop_id = shop&.id
        end
        item.update_available
        item.save
      end
    end
  end

  def fetch_item_word
    while true
      items = TaobaoItem.where(fetch_word_at: nil).reverse(:volume).limit(1000)
      break if items.empty?
      items.each do |item|
        item.fetch_word_at = Time.now
        if item.click_url
          ret = TaobaoClinet.word_create(text: item.title, url: item.click_url_https)
          if TaobaoClinet.error_result?(ret)
            puts ret.inspect
          else
            item.click_word = ret['data']['model']
          end
        end
        if item.coupon_url
          ret = TaobaoClinet.word_create(text: item.title, url: item.coupon_url_https)
          if TaobaoClinet.error_result?(ret)
            puts ret.inspect
          else
            item.coupon_word = ret['data']['model']
          end
        end
        item.update_available
        item.save
      end
    end
  end

  def fetch_id_data(material_set, material_obj, material_id_arr)
    material_ids = material_id_arr[1].is_a?(Array) ? material_id_arr[1] : [material_id_arr[1]]
    material_ids.each do |material_id|
      params = {adzone_id: AppConfig.taobaoke.adzone_id, material_id: material_id, page_size: 100, page_no: 1}
      while true
        ret = TaobaoClinet.optimus_material(params)
        break if TaobaoClinet.empty_result?(ret)
        if TaobaoClinet.error_result?(ret)
          puts ret.inspect
          break
        end
        save_id_data(material_set, material_obj, [material_id_arr[0], material_id], ret)
        break if ret['result_list'].length < params[:page_size]
        params[:page_no] += 1
      end
    end
  end

  def save_id_data(material_set, material_obj, material_id_arr, ret)
    if ret['result_list'].nil?
      puts ret.inspect
    end
    ret['result_list'].each do |result|
      shop = find_or_save_shop(result)
      find_or_save_item(material_set, material_obj, material_id_arr, shop, result)
    end
  end

  def find_or_save_shop(result)
    return if result['seller_id'].nil?
    shop = TaobaoShop.first(shop_id: result['seller_id'])
    return shop if shop

    # optimus_material 接口有些返回的是卖家名称,而不是店铺名
    shop = TaobaoShop.new(shop_id: result['seller_id'], title: result['nick'], kind: result['user_type'])
    shop.save
    shop
  end

  def find_or_save_item(material_set, material_obj, material_id_arr, shop, result)
    return if result['coupon_amount'].to_i <= 0 && result['presale_deposit'].to_i <= 0 # 即无优惠券,又无预售的直接跳过

    item = TaobaoItem.first(item_id: result['item_id'])
    word_changed = false
    if item.nil?
      item = TaobaoItem.new(item_id: result['item_id']) 
    elsif ((item.coupon_start_time.to_i * 1000) != result['coupon_start_time'].to_i || (item.presale_start_time.to_i * 1000) != result['presale_start_time'])
      word_changed = true
    end
    item.set(
      title: result['title'],
      volume: result['volume'],
      pict_url: result['pict_url'],
      click_url: result['click_url'],
      orig_price: result['zk_final_price'],
    )

    item.shop_id = shop&.id if item.shop_id.nil?
    item.fetch_shop_at = Time.now if item.fetch_shop_at.nil? && item.shop_id
    item.category_id = @taobao_categories.find{|a| a.name == material_id_arr[0]}.id if item.category_id.nil?
    item.kind = TaobaoItem::KINDS[:normal] if item.kind.nil?
    item.material_kind = "#{material_set['name']}|#{material_obj['name']}" if item.material_kind.nil?

    if result['coupon_amount'] && result['coupon_amount'].to_i > 0
      item.kind = TaobaoItem::KINDS[:coupon]
      item.set(
        coupon_amount: result['coupon_amount'],
        coupon_start_fee: result['coupon_start_fee'],
        coupon_total_count: result['coupon_total_count'],
        coupon_remain_count: result['coupon_remain_count'],
        coupon_start_time: result['coupon_start_time'].nil? ? Date.today : microsecond2time(result['coupon_start_time']), # 当时间为空时,则认为优惠券只有当天有效
        coupon_end_time: result['coupon_start_time'].nil? ? Date.today + 1 : microsecond2time(result['coupon_end_time']),
        coupon_url: result['coupon_share_url'],
      )
    else
      item.set(
        coupon_amount: nil,
        coupon_start_fee: nil,
        coupon_total_count: nil,
        coupon_remain_count: nil,
        coupon_start_time: nil,
        coupon_end_time: nil,
        coupon_url: nil
      )
    end

    presale_discount_fee = 0
    if result['presale_deposit'] && result['presale_deposit'].to_i > 0
      item.kind = TaobaoItem::KINDS[:presale]
      if result['presale_discount_fee_text']
        presale_discount_fee = result['presale_discount_fee_text'].scan(/减(\d+)元/).flatten[0].to_i
      end
      item.set(
        presale_deposit: result['presale_deposit'],
        presale_discount_fee_text: result['presale_discount_fee_text'],
        presale_discount_fee: presale_discount_fee,
        presale_start_time: microsecond2time(result['presale_start_time']),
        presale_end_time: microsecond2time(result['presale_end_time']),
        presale_tail_start_time: microsecond2time(result['presale_tail_start_time']),
        presale_tail_end_time: microsecond2time(result['presale_end_time']),
      )
    else
      item.set(
        presale_deposit: nil,
        presale_discount_fee_text: nil,
        presale_discount_fee: nil,
        presale_start_time: nil,
        presale_end_time: nil,
        presale_tail_start_time: nil,
        presale_tail_end_time: nil,
      )
    end

    item.price = result['zk_final_price'].to_i
    item.price -= result['coupon_amount'].to_i if result['coupon_amount'].to_i > 0
    item.price -= presale_discount_fee if presale_discount_fee > 0

    if item.shop_id.nil?
      item.fetch_shop_at = nil
    elsif item.click_word.nil? || item.coupon_word.nil? || word_changed
      item.fetch_word_at = nil
    end
    item.update_available

    item.save
    item
  end

  def microsecond2time(microsecond)
    return if microsecond.to_i == 0
    Time.at(microsecond.to_i / 1000)
  end
end

task :test_optimus_material do
  params = {adzone_id: 109639900014, material_id: 26483, page_size: 100, page_no: 1}
  puts TaobaoClinet.optimus_material(params)
end

task :import_taobao_categories do
  data = Psych.load_file("./data/taobao_categories.yaml")
  data['taobao_categories'].each do |cat|
    TaobaoCategory.find_or_create(name: cat['name']){ |tcat| tcat.position = cat['position']}
  end
end

task :fetch_material do
  TaobaoMaterialTask.new.run
end
