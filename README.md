drop database generalstorespider;
create database generalstorespider charset utf8mb4;

bundle exec sequel -m migrations 'mysql2://localhost/generalstorespider?encoding=utf8mb4&user=root'

bundle exec rake import_taobao_categories
