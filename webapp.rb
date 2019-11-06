require 'sinatra/base'

require './lib/models'
require './lib/serializers'

class WebApp < Sinatra::Application
  before do
    content_type :json
  end

  get '/' do
    ret = DB['SELECT 1']
    ret.all
    "OK"
  end

  get '/api/items' do
    sleep 1
    items = TaobaoItem.exclude(id: params['ids'].to_s.split(',')).order(Sequel.desc(:volume)).limit(24)
    TaobaoItemSerializer.new(items, is_collection: true).serialized_json
  end
end
