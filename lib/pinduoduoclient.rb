require 'net/http'
require "digest/md5"
require 'json'
require './lib/app_config'

class PinduoduoClinet
  APP_KEY = AppConfig.duoduoke.client_id
  APP_SECRET = AppConfig.duoduoke.client_secret

  class << self
    def goods_recommend(params)
      params[:type] = 'pdd.ddk.goods.recommend.get'
      execute(params)
    end

    def execute(params)
      puts "execute params #{params.inspect}"
      params = process_params(params.dup)
      uri = URI('https://gw-api.pinduoduo.com/api/router')
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

      params[:client_id] = APP_KEY
      params[:data_type] = 'JSON'
      params[:timestamp] = Time.now.to_i

      params[:'sign'] = sign_params(params)
      params
    end

    def sign_params(params)
      # delete access_token
      ret = "#{APP_SECRET}#{params.sort_by{ |k, v| k.to_s }.flatten.join}#{APP_SECRET}"
      Digest::MD5.hexdigest(ret).upcase
    end
  end
end
