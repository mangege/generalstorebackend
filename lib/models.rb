require 'sequel'

# TODO config file, fix max_connections
DB = Sequel.connect('mysql2://localhost/generalstorespider?encoding=utf8mb4&user=root')


class User < Sequel::Model
end

class TaobaoCategory < Sequel::Model
end

class TaobaoShop < Sequel::Model
end

class TaobaoItem < Sequel::Model
end
