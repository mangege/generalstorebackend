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
      items = TaobaoItem.where(available: true).order(Sequel.desc(:volume)).limit(24)
      items = items.where(material_kind: params['material_kind']) if params['material_kind'] && params['material_kind'] != ''
      if user.nil?
        items = items.offset(params['offset'] || 0)
      else
        UserTaobaoItem.add_read(user.id, item_ids)
        # 有使用 qualify , taobao_items 表的过滤条件请写在此行上面
        items = items.exclude(id: item_ids).qualify(:taobao_items)
        items = items.left_outer_join(:user_taobao_items, taobao_item_id: :id, user_id: user.id).where(user_id: nil).qualify(:user_taobao_items)
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
