require 'net/http'
require "digest/md5"
require 'json'
require './lib/app_config'

class TaobaoClinet
  APP_KEY = AppConfig.taobaoke.app_key
  APP_SECRET = AppConfig.taobaoke.app_secret

  class << self
    def optimus_material(params)
      params[:method] = 'taobao.tbk.dg.optimus.material'
      execute(params)
    end

    def item_info(params)
      params[:method] = 'taobao.tbk.item.info.get'
      execute(params)
    end

    def word_create(params)
      params[:method] = 'taobao.tbk.tpwd.create'
      execute(params)
    end

    def execute(params)
      puts "execute params #{params.inspect}"
      params = process_params(params.dup)
      uri = URI('https://eco.taobao.com/router/rest')
      res = Net::HTTP.post_form(uri, params)
      JSON.parse(res.body)
    end

    def empty_result?(ret)
      ret.dig('error_response', 'sub_code') == '50001'
    end

    def error_result?(ret)
      !ret['error_response'].nil?
    end

    def process_params(params)
      params.delete(:sign)

      params[:app_key] = APP_KEY
      params[:v] = '2.0'
      params[:format] = 'json'
      params[:simplify] = true
      params[:sign_method] = 'md5'
      params[:timestamp] = Time.now.strftime("%Y-%m-%d %H:%M:%S")

      params[:'sign'] = sign_params(params)
      params
    end

    def sign_params(params)
      ret = "#{APP_SECRET}#{params.sort_by{ |k, v| k.to_s }.flatten.join}#{APP_SECRET}"
      Digest::MD5.hexdigest(ret).upcase
    end
  end
end
