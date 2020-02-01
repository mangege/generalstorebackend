require './lib/pinduoduoclient'

task :test_goods_recommend do
  params = {}
  puts PinduoduoClinet.goods_recommend(params)
end
