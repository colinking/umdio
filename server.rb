# umdio api core application. brings in other dependencies as needed.
ENV['RACK_ENV'] ||= 'development'
 
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

require 'grape'
require 'mongo'
require 'json'

include Mongo

class UMDIOServer < Grape::API

  # Explicitly set this as the root file
  # set :root, File.dirname(__FILE__)

  # fix strange scraper bug by explicitly setting the server
  # reference: http://stackoverflow.com/questions/17334734/how-do-i-get-sinatra-to-work-with-httpclient
  
  
  # configure do
  #   # set up mongo database - code from ruby mongo driver tutorial
  #   host = ENV['MONGO_RUBY_DRIVER_HOST'] || 'localhost'
  #   port = ENV['MONGO_RUBY_DRIVER_PORT'] || MongoClient::DEFAULT_PORT
  #   puts "Connecting to mongo on #{host}:#{port}"
  #   # we might need other databases for other endpoints, but for now this is fine, with multiple collections
  #   set :courses_db, MongoClient.new(host, port, pool_size: 20, pool_timeout: 5).db('umdclass') 
  #   set :buses_db, MongoClient.new(host,port, pool_size: 20, pool_timeout: 5).db('umdbus')
  #   set :map_db, MongoClient.new(host,port, pool_size: 20, pool_timeout: 5).db('umdmap')
  # end

  # configure :development do
  #   # TODO: fix weird namespace conflict and install better_errors
  #   use BetterErrors::Middleware
  #   BetterErrors.application_root = __dir__
  # end

  # before application/request starts
  before do
    content_type 'application/json'
    cache_control :public, max_age: 86400
    params[:page] ||= 1
    params[:per_page] ||= 10
  end

  # load in app helpers & controllers
  Dir["./app/helpers/*.rb"].each { |file| require file }
  Dir["./app/controllers/*.rb"].each { |file| require file }
  # require './root.rb'

  # register the helpers
  # helpers Sinatra::UMDIO::Helpers
  # helpers Sinatra::Param

  # Make a logger available in future routes
  helpers do
    def logger
      API.logger
    end
  end

  # Tell Grape to catch errors and handle them like a normal API error
  # rescue_from :all

  # MOUNT ALL RESOURCES HERE

  route :any, '*path' do
    error! # or something else
  end
end
