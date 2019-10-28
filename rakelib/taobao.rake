require 'yaml'
require './lib/taobaoclient'
require './lib/models'

class TaobaoMaterialTask
  def run
    load_id_data
    process_id_data
  end

  private
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

  def fetch_id_data(material_set, material_obj, material_id_arr)
    params = {adzone_id: 109639900014, material_id: material_id_arr[1], page_size: 100, page_no: 1}
    while true
      ret = TaobaoClinet.optimus_material(params)
      break if TaobaoClinet.empty_result?(ret)
      save_id_data(material_set, material_obj, material_id_arr, ret)
      break if ret['result_list'].length < params[:page_size]
      params[:page_no] += 1
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

    shop = TaobaoShop.new(shop_id: result['seller_id'], title: result['nick'], kind: result['user_type'])
    shop.update_flagship
    shop.save
    shop
  end

  def find_or_save_item(material_set, material_obj, material_id_arr, shop, result)
    item = TaobaoItem.first(item_id: result['item_id'])
    # FIXME update api
    if item
      # puts "item exist #{item.item_id} #{material_set['name']}|#{material_obj['name']} - #{item.material_kind}"
      return item
    end
    item = TaobaoItem.new(
      title: result['title'],
      item_id: result['item_id'],
      volume: result['volume'],
      pict_url: result['pict_url'],
      click_url: result['click_url'],
      orig_price: result['zk_final_price'],
    )

    item.shop_id = shop&.id
    item.category_id = @taobao_categories.find{|a| a.name == material_id_arr[0]}.id
    item.kind = TaobaoItem::KINDS[:normal]
    item.material_kind = "#{material_set['name']}|#{material_obj['name']}"

    if result['coupon_amount'] && result['coupon_amount'].to_i > 0
      item.kind = TaobaoItem::KINDS[:coupon]
      item.set(
        coupon_amount: result['coupon_amount'],
        coupon_start_fee: result['coupon_start_fee'],
        coupon_total_count: result['coupon_total_count'],
        coupon_remain_count: result['coupon_remain_count'],
        coupon_start_time: microsecond2time(result['coupon_start_time']),
        coupon_end_time: microsecond2time(result['coupon_end_time']),
        coupon_url: result['coupon_share_url'],
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
        presale_discount_fee: presale_discount_fee
      )
    end

    item.price = result['zk_final_price'].to_i
    item.price -= result['coupon_amount'].to_i if result['coupon_amount'].to_i > 0
    item.price -= presale_discount_fee if presale_discount_fee > 0

    # TODO  step, word

    item.save
    item
  end

  def microsecond2time(microsecond)
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
