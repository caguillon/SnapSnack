require "sinatra"
require 'sinatra/flash'
require_relative "authentication.rb"

#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

class Post
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