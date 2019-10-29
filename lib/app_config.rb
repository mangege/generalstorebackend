require "ostruct"
require 'json'
require 'yaml'

app_config_data = Psych.load_file("./config/app.yaml")
AppConfig = JSON.parse(app_config_data.to_json, object_class: OpenStruct)
