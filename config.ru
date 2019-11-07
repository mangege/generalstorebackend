require 'bundler/setup'
require 'rack/contrib'

require './webapp'

use Rack::PostBodyContentTypeParser

run WebApp
