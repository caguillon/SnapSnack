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
	property :completed_on, Text
    property :user, String #the user that is posting the task
    property :delivery_location, Text
    property :order_description, Text
    property :time_to_be_completed, Text
    property :accepted_by, Text # the user the will complete the order
	property :price, Integer
	property :grand_total, Integer
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
	@rev = @orders.sort_by{ |h| h[:id] }.reverse! #ordering by most recent snack request
	erb :dashboard
end

get "/dashboard/snapper" do
	authenticate!
	snapify!
	@orders = Order.all
	@ttc = @orders.sort_by{ |h| h[:time_to_be_completed] } #ordering by the time to be completed on snapper dashboard
	@rev = @orders.sort_by{ |h| h[:id] }.reverse!
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
	@arr = []
	if chicken_sandwhich
		@food = Order.new
		@food.order_description = "Chick-Fil-A Chicken Sandwhich"
		@food.price = 421
		@arr.push @food
	end
	if nuggets
		@food = Order.new
		@food.order_description= "Chick-Fil-A Chicken Nuggets"
		@food.price = 519
		@arr.push @food
	end
	if biscuit
		@food = Order.new
		@food.order_description = "Chick-Fil-A Breakfast Biscuit"
		@food.price = 362
		@arr.push @food
	end
	if beef_guisado
		@food = Order.new
		@food.order_description= "El Pato Beef Guisado"
		@food.price = 863
		@arr.push @food
	end
	if beef_fajita
		@food = Order.new
		@food.order_description = "El Pato Beef Fajita"
		@food.price = 751
		@arr.push @food
	end
	if gorditas
		@food = Order.new
		@food.order_description= "El Pato Gorditas"
		@food.price = 499
		@arr.push @food
	end
	if firecracker
		@food = Order.new
		@food.order_description = "Sushi Firecracker Roll"
		@food.price = 899
		@arr.push @food
	end
	if noodles
		@food = Order.new
		@food.order_description= "Sushi Lo-Mein Noodles"
		@food.price = 556
		@arr.push @food
	end
	if rice
		@food = Order.new
		@food.order_description = "Sushi Fried Rice"
		@food.price = 395
		@arr.push @food
	end
	if pepperoni
		@food = Order.new
		@food.order_description= "Pizza Hut Pepperoni 1 slice"
		@food.price = 299
		@arr.push @food
	end
	if hawaiian
		@food = Order.new
		@food.order_description = "Pizza Hut Hawaiian Large"
		@food.price = 799
		@arr.push @food
	end
	if wings
		@food = Order.new
		@food.order_description= "Pizza Hut Wings 8pc"
		@food.price = 954
		@arr.push @food
	end
	if coke
		@food = Order.new
		@food.order_description= "Coke"
		@food.price = 225
		@arr.push @food
	end
	if lem
		@food = Order.new
		@food.order_description= "Lemonade"
		@food.price = 299
		@arr.push @food
	end
	if power
		@food = Order.new
		@food.order_description= "Powerade"
		@food.price = 159
		@arr.push @food
	end
	@arr.each do |a|
		order += a.order_description + ', '
		price += a.price
	end
	if(delivery != nil && order != nil && time_com != nil)
		@o = Order.new
		@o.delivery_location = delivery
		@o.order_description = order
		@o.price = price
		@o.grand_total = price + (price * 0.10) + 500 + (price * 0.0825) #$order + $service charge + $delivery fee + $tax fee
		@o.time_to_be_completed = time_com
		@o.user = current_user.email #each email is unique
		@o.save
	end
	
	erb :orderSubmission
end

post "/charge/:order_id" do
	# Amount in cents
	order = Order.get(params[:order_id])
	@amount = order.grand_total
  
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

# snapper complete an order, so update orders table
post "/delivery/completeo" do
	authenticate!
	oid = params["complete"]
	
	#gets the order from table
	o = Order.get(oid.to_i)

	#updates info on order
	o.completed = true
	o.completed_on = DateTime.now.strftime("%d/%m/%Y %H:%M %p")
    o.save
	
	redirect "/dashboard/snapper"
end