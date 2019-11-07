require 'logger'
require 'securerandom'
require 'sequel'
require './lib/app_config'

DB = Sequel.connect(AppConfig.database.to_h) 
# DB.loggers << Logger.new($stdout)
Sequel::Model.plugin :timestamps


class User < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence :uuid
    validates_unique :uuid
  end

  def self.gen
    user = User.new
    user.uuid = SecureRandom.uuid
    user
  end
end

class TaobaoCategory < Sequel::Model
  plugin :validation_helpers
  one_to_many :items, key: :category_id, class: :TaobaoItem

  def validate
    super
    validates_presence :name
    validates_unique :name
  end
end

class TaobaoShop < Sequel::Model
  KINDS = {c: 0, b: 1}
  plugin :validation_helpers
  one_to_many :items, key: :shop_id, class: :TaobaoItem

  def validate
    super
    validates_presence [:title, :shop_id, :kind]
    validates_unique :shop_id
  end
end

class TaobaoItem < Sequel::Model
  KINDS = {normal: 1, coupon: 2, presale: 3}

  plugin :validation_helpers
  many_to_one :shop, key: :shop_id, class: :TaobaoShop
  many_to_one :category, key: :category_id, class: :TaobaoCategory

  def referral_url
    coupon_url || click_url
  end

  def referral_word
    coupon_word || click_word
  end

  def click_url_https
    "https:#{click_url}"
  end

  def coupon_url_https
    "https:#{coupon_url}"
  end

  def update_available
    current_time = Time.now
    self.available = !shop_id.nil? && !click_word.nil? && ((!coupon_start_time.nil? && coupon_start_time < current_time && coupon_end_time > current_time) || (!presale_start_time.nil? && presale_start_time < current_time && presale_end_time > current_time))
  end

  def validate
    super
    presence_attrs = [:title, :item_id, :category_id, :pict_url, :click_url, :kind, :material_kind, :available]
    presence_attrs.concat([:click_word, :shop_id]) if available
    validates_presence(presence_attrs)
    validates_unique :item_id
  end
end

class UserTaobaoItem < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence [:user_id, :taobao_item_id]
    validates_unique [:user_id, :taobao_item_id]
  end

  def self.add_read(user_id, item_ids)
    return if user_id.nil? || item_ids.nil? || item_ids.empty?

    item_ids = item_ids.collect(&:to_i)
    exist_item_ids = self.where(user_id: user_id, taobao_item_id: item_ids).select_map(:taobao_item_id)
    (item_ids - exist_item_ids).each do |item_id|
      self.new(user_id: user_id, taobao_item_id: item_id).save rescue nil # Sequel::UniqueConstraintViolation
    end
  end
end

UserTaobaoItem.unrestrict_primary_key
