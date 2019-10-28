require 'logger'
require 'sequel'

# TODO config file, fix max_connections
DB_OPTIONS = {}
#DB_OPTIONS = {logger: Logger.new(STDOUT)}
DB = Sequel.connect('mysql2://localhost/generalstorespider?encoding=utf8mb4&user=root', DB_OPTIONS) 
Sequel::Model.plugin :timestamps


class User < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence :uuid
    validates_unique :uuid
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

  def update_flagship
    self.flagship = (kind == KINDS[:b] &&  title.end_with?('旗舰店'))
  end

  def validate
    super
    validates_presence [:title, :shop_id, :kind, :flagship]
    validates_unique :shop_id
  end
end

class TaobaoItem < Sequel::Model
  KINDS = {normal: 1, coupon: 2, presale: 3}
  STEPS = {finished: 0, shop: 1, word: 2}

  plugin :validation_helpers
  many_to_one :shop, key: :shop_id, class: :TaobaoShop
  many_to_one :category, key: :category_id, class: :TaobaoCategory

  def validate
    super
    presence_attrs = [:title, :item_id, :category_id, :pict_url, :click_url, :kind, :material_kind, :step, :available]
    validates_presence(presence_attrs.concat([:click_word, :shop_id])) if STEPS[:finished] == step
    validates_unique :item_id
  end
end
