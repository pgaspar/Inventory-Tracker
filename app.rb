# encoding: utf-8
require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'erb'
require 'data_mapper'
require "sinatra/reloader" if development?
require 'date'
require 'rack-datamapper-session'

# Database - setup for both local and remote environments

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db.sqlite3")

# Session - Force session expiration after 2 weeks

use Rack::Session::DataMapper, :expire_after => 15*24*3600

# Models

class User
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String
  
  has n,   :consumptionRecords
  
  def monthly_records(month, year)
    begin_date = Date.new(year, month)
    end_date = begin_time.next_month
    consumptionRecords.all(:created_at => (begin_date.to_time .. end_date.to_time))
  end
  
  # Some utility methods - naming could be improved.
  
  def records_for_product(product)
    consumptionRecords.all(:product => product)
  end
  
  def total_price
    total_price_sum = consumptionRecords.map(&:price).inject(:+)
    sprintf "%.2f", total_price_sum || 0 # Using sprintf to avoid weird float errors (0.5999999 instead of 0.6).
  end
  
  def type_price(product)
    product_price_sum = records_for_product(product).map(&:price).inject(:+)
    sprintf "%.2f", product_price_sum || 0 # Using sprintf to avoid weird float errors (0.5999999 instead of 0.6).
  end
end

class ConsumptionRecord
  include DataMapper::Resource
  property :id,           Serial
  property :created_at,   DateTime
  property :price,        Float, :required => true
  property :batch,        Boolean, :default => false    # Batch records should not be used for statistics, since their timestamps are inaccurate.
  
  belongs_to :user
  belongs_to :product
end

class Product
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String, :required => true
  property :price,        Float, :required => true
  property :style,        String                        # Adds specific CSS styling to this product. Currently unused.
  
  has n,   :consumptionRecords
end

DataMapper.finalize
DataMapper.auto_upgrade!

# Controllers

before do
  # Get current user from session before doing anything.
  @me = User.get(session[:user]) if session[:user]
end

get '/' do
  @users = User.all
  @products = Product.all
  erb :index
end

post '/login' do
  session[:user] = User.get(params[:id]).id                       # Make sure the selected user exists and save its id to session.
  call env.merge("PATH_INFO" => '/product/' + params[:prod_id])   # After-login redirect to the requested product page.
end

get '/logout' do
  session.clear
  redirect '/'
end

post '/product/:id' do |id|
  prod = Product.get(id)
  halt 404 if prod.nil?

  quantity = params[:quantity].to_i
  quantity = 1 unless (1..5).include?(quantity)   # Make sure quantity is within the [1, 5] integer interval (this is hardcoded).

  # Force login if no user in session.
  unless @me
    @users = User.all
    return erb :login, :locals => {:prod_id => id, :quantity => quantity}
  end
  
  # Create 'quantity' number of consumption records.
  quantity.times.each do
    @me.consumptionRecords.create(:product => prod, :price => prod.price, :batch => quantity != 1)
  end
  
  @products = Product.all
  erb :done, :locals => {:confirmation_msg => ["Registado.", "Ok, já apontei.", "Done.", "Agora vai trabalhar.", "E Red Bull, não?"].sample}
end

# Admin actions

get '/admin' do
  protected!
  @users = User.all
  @products = Product.all
  erb :"admin/index"
end

post '/admin/users/add' do
  protected!
  User.create(:name => params[:name])
  redirect '/admin'
end

post '/admin/user/:id/remove' do |id|
  protected!
  User.get(id).destroy
  redirect '/admin'
end

get '/admin/user/:id' do |id|
  protected!
  @user = User.get(id)
  @products = Product.all
  erb :"admin/user"
end

post '/admin/products/add' do
  protected!
  Product.create(:name => params[:name], :price => params[:price], :style => params[:style])
  redirect '/admin'
end

post '/admin/product/:id/remove' do |id|
  protected!
  Product.get(id).destroy
  redirect '/admin'
end

get '/admin/product/:id' do |id|
  protected!
  @product = Product.get(id)
  erb :"admin/product"
end

post '/admin/product/:id/edit' do |id|
  protected!
  Product.get(id).update(:name => params[:name], :price => params[:price], :style => params[:style])
  redirect '/admin'
end

# Helpers

helpers do

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [ENV['ADMIN_USERNAME'] || 'admin', ENV['ADMIN_PASSWORD'] || 'password']
  end

end