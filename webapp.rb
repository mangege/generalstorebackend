require "json"
require 'sinatra/base'
require "sinatra/namespace"
require "sinatra/reloader"

require './lib/models'
require './lib/serializers'

class WebApp < Sinatra::Application
  register Sinatra::Namespace
  configure :development do
    register Sinatra::Reloader
    also_reload './*.rb', './lib/*.rb'
  end

  before do
    content_type :json
  end

  get '/' do
    ret = DB['SELECT 1']
    ret.all
    {ok: true}.to_json
  end

  namespace '/api' do
    post '/users' do
      user = User.gen
      user.save
      InsecureUserSerializer.new(user).serialized_json
    end

    post '/login' do
      uuid = params['uuid']
      if uuid.nil? || uuid.size != 36
        status 422
        return {ok: false, msg: '登录口令无效'}.to_json
      end

      user = User.first(uuid: uuid)
      if user.nil?
        status 422
        return {ok: false, msg: '登录失败'}.to_json
      end

      InsecureUserSerializer.new(user).serialized_json
    end

    get '/items' do
      user = current_user
      items = []
      item_ids = params['item_ids'].to_s.split(',')
      items = TaobaoItem.exclude(id: item_ids).where(available: true).order(Sequel.desc(:volume)).limit(24)
      if params['material_kind']
        items = items.where(material_kind: params['material_kind'])
      end
      unless user.nil?
        UserTaobaoItem.add_read(user.id, item_ids)
        items = items.left_outer_join(:user_taobao_items, taobao_item_id: :id, user_id: user.id).where(user_id: nil)
      end
      # puts items.sql
      TaobaoItemSerializer.new(items, is_collection: true).serialized_json
    end

    private
    # TODO action cache
    def current_user
      uuid = request.env['HTTP_X_TOKEN'] || params['token']
      User.first(uuid: uuid)
    end
  end
end
