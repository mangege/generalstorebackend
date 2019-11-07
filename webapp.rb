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
      items = TaobaoItem.exclude(id: params['ids'].to_s.split(',')).order(Sequel.desc(:volume)).limit(24)
      TaobaoItemSerializer.new(items, is_collection: true).serialized_json
    end
  end
end
