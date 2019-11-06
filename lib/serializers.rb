require 'fast_jsonapi'

class TaobaoItemSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :title, :price, :orig_price, :volume, :pict_url, :referral_url, :referral_word, :kind, :available
end
