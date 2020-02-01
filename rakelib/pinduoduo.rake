require './lib/pinduoduoclient'

task :test_goods_recommend do
  params = {limit: 400}
  puts PinduoduoClinet.goods_recommend(params)
end
