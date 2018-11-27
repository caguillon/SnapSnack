require "sinatra"
require 'sinatra/flash'
require_relative "authentication.rb"
require 'stripe'

set :publishable_key, 'pk_test_GcpPtLGp2FWGxTcxzZdEd7fm'
set :secret_key, 'sk_test_NkKAAhxeUkoDfJz9PpCew4jW'

Stripe.api_key = settings.secret_key

#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

#make an admin user if one doesn't exist!
if User.all(administrator: true).count == 0
	u = User.new
	u.fname = "Admin"
	u.lname = "Istrator"
	u.email = "admin@admin.com"
	u.password = "admin"
	u.administrator = true
	u.save
end

class Order
	include DataMapper::Resource
	property :id, Serial

    property :created_at, DateTime
    
    property :delivery_location, Text
    property :order_description, Text
    property :time_for_order_to_be_completed, Text
    property :accepted_by, Text #should this be something else??
    
    property :post_accepted, Boolean, :default => false
    property :completed, Boolean, :default => false
end

get "/" do
	erb :index
end

get "/dashboard" do
	authenticate!
	erb :dashboard
end

get "/order" do
	authenticate!
	erb :orderform
end

post "/charge" do
	# Amount in cents
	@amount = 500
  
	customer = Stripe::Customer.create(
	  :email => 'customer@example.com',
	  :source  => params[:stripeToken]
	)
  
	charge = Stripe::Charge.create(
	  :amount      => @amount,
	  :description => 'Sinatra Charge',
	  :currency    => 'usd',
	  :customer    => customer.id
	)
	erb :charge
	cu = current_user
	cu.pro = true
	cu.save
  end