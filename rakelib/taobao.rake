require 'yaml'
require './lib/taobaoclient'
require './lib/models'

class TaobaoMaterialTask
  def run
    load_id_data
    process_id_data
  end

  private
  def load_id_data
    @id_data = Psych.load_file("./data/taobao_material_ids.yaml")
  end

  def process_id_data
    @id_data['taobao_material_ids'].each do |material_set|
      next if material_set['disabled']
      material_set['kinds'].each do |material_obj|
        fetch_id_data(material_set, material_obj)
      end
    end
  end

  def fetch_id_data(material_set, material_obj)
    params = {adzone_id: 109639900014, material_id: 26483, page_size: 100, page_no: 1}
    while true
      ret = TaobaoClinet.optimus_material(params)
      break if TaobaoClinet.empty_result?(ret)
      save_id_data(material_set, material_obj, ret)
      break if ret['result_list'].length < params[:page_size]
      params[:page_no] += 1
    end
  end

  def save_id_data(material_set, material_obj, ret)
    ret['result_list'].each do |result|
      puts result
    end
  end
end

task :test_optimus_material do
  params = {adzone_id: 109639900014, material_id: 26483, page_size: 100, page_no: 1}
  puts TaobaoClinet.optimus_material(params)
end

task :fetch_material do
  TaobaoMaterialTask.new.run
end
