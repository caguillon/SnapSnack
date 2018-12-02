require "sinatra"
require 'sinatra/flash'
require_relative "authentication.rb"
require "stripe"

set :publishable_key, 'pk_test_GcpPtLGp2FWGxTcxzZdEd7fm'
set :secret_key, 'sk_test_NkKAAhxeUkoDfJz9PpCew4jW'

Stripe.api_key = settings.secret_key

class Order
	include DataMapper::Resource
	property :id, Serial

    property :created_at, DateTime
    property :user, String #the user that is posting the task
    property :delivery_location, Text
    property :order_description, Text
    property :time_to_be_completed, Text
    property :accepted_by, Text # the user the will complete the order
    
    property :post_accepted, Boolean, :default => false
    property :completed, Boolean, :default => false
end

# we don't need to include again the datamapper code since it's already in the user.rb

# automatically creates the order table
Order.auto_upgrade!

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

get "/" do
	erb :index
end

get "/dashboard" do
	authenticate!
	@orders = Order.all
	erb :dashboard
end

get "/dashboard/snapper" do
	authenticate!
	@orders = Order.all(completed: false)
	erb :snapper_dashboard
end

get "/order" do
	authenticate!
	erb :orderform
end

post "/order/create" do 
	authenticate!
	delivery = params["dloc"]
	order_des = params["odescription"]
	time_com = params["time"]

	if(delivery != nil && order_des != nil && time_com != nil)
		o = Order.new
		o.delivery_location = delivery
		o.order_description = order_des
		o.time_to_be_completed = time_com
		o.user = current_user.email #each email is unique
		o.save
	end
	erb :orderSubmission
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
	erb :dashboard
  end

# a consumer can become a deliverer and earn profit $ by completing orders
 get "/upgrade/delivery" do
	authenticate!
	#if you are not pro or admin, can upgrade
	if admin? == false && delivery? == false
		# FIXME: need to figure out checkmark input to get code to work
		erb :deliveryform
	else
		redirect "/"
	end
end

# changes the user to also be a delivery
post "/delivery/new" do 
	authenticate!
	#optional: if user actually checked that they want to upgrade
	upgrade = params["upgrade"]

	if upgrade == "on"
		upgrade!
		erb :successful_upgrade
	end

end