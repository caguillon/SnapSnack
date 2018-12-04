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
    property :price, Integer
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
	snapify!
	@orders = Order.all
	erb :snapper_dashboard
end

get "/dashboard/admin" do
	authenticate!
	administrate!
	@orders = Order.all
	erb :admin_dashboard
end

get "/order" do
	authenticate!
	erb :orderform
end

post "/order/create" do 
	authenticate!
	delivery = params["dloc"]
	time_com = params["time"]
	######checking each checkbox to see if its null#####

	#chickfila#
	chicken_sandwhich = !params["chicken_sandwhich"].nil?
	nuggets = !params["nuggets"].nil?
	biscuit = !params["biscuit"].nil?

	#el pato#
	beef_guisado = !params["beef_guisado"].nil?
	beef_fajita = !params["beef_fajita"].nil?
	gorditas = !params["gorditas"].nil?

	#sushi#
	firecracker = !params["firecracker"].nil?
	noodles = !params["noodles"].nil?
	rice = !params["rice"].nil?

	#pizza hut#
	pepperoni = !params["pepperoni"].nil?
	hawaiian = !params["hawaiian"].nil?
	wings = !params["wings"].nil?

	#drinks#
	coke = !params["coke"].nil?
	lem = !params["lemonade"].nil?
	power = !params["powerade"].nil?

	order = ""
	price = 0

	####concatenating string for order####
	order += "Chik-Fil-A Chicken Sandwhich\n" if chicken_sandwhich
	order += "Chik-Fil-A Chicken Nuggets\n" if nuggets
	order += "Chik-Fil-A Breakfast Biscuit\n" if biscuit

	order += "El Pato Beef Guisado\n" if beef_guisado
	order += "El Pato Beef/Chicken Fajita\n" if beef_fajita
	order += "El Pato Gorditas\n" if gorditas

	order += "Sushi Firecracker\n" if firecracker
	order += "Sushi Noodles\n" if noodles
	order += "Sushi Fried Rice\n" if rice

	order += "Pizza Hut Pepperoni 1 slice\n" if pepperoni
	order += "Pizza Hut Hawaiian\n" if hawaiian
	order += "Pizza Hut Wings 8pc\n" if wings

	order += "Coke\n" if coke
	order += "Lemonade\n" if lem
	order += "Powerade\n" if power

	####adding the total price of everything to charge####
	price += 421 if chicken_sandwhich
	price += 519 if nuggets
	price += 362 if biscuit

	price += 863 if beef_guisado
	price += 752 if beef_fajita
	price += 651 if gorditas

	price += 981 if firecracker
	price += 562 if noodles
	price += 499 if rice

	price += 495 if pepperoni
	price += 1499 if hawaiian
	price += 856 if wings

	price += 255 if coke
	price += 290 if lem
	price += 199 if power

	if(delivery != nil && order != nil && time_com != nil)
		@o = Order.new
		@o.delivery_location = delivery
		@o.order_description = order
		@o.price = price
		@o.time_to_be_completed = time_com
		@o.user = current_user.email #each email is unique
		@o.save
	end
	
	erb :orderSubmission
end

post "/charge/:order_id" do
	# Amount in cents
	order = Order.get(params[:order_id])
	@amount = order.price
  
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
	redirect "/dashboard"
end

# a consumer can become a deliverer and earn profit $ by completing orders
 get "/upgrade/delivery" do
	authenticate!
	#if you are not pro or admin, can upgrade
	if admin? == false && delivery? == false
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

# snapper accepted an order, so update orders table
post "/delivery/accepto" do
	authenticate!
	oid = params["order"]

	#gets the order from table
	o = Order.get(oid.to_i)
	
	#updates info on order
	o.accepted_by = current_user.email
    o.post_accepted = true
    o.save
    
	redirect "/dashboard/snapper"
end

# snapper accepted an order, so update orders table
post "/delivery/completeo" do
	authenticate!
	oid = params["complete"]
	
	#gets the order from table
	o = Order.get(oid.to_i)
	
	#updates info on order
	o.completed = true
    o.save
    
	redirect "/dashboard/snapper"
end