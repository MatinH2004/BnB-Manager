require "sinatra"
require "tilt/erubis"

require "yaml"
require "bcrypt"
require "pry"

require_relative "database_api"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload("database_api.rb")
end

helpers do
  def no_tenants?
    @apartment[0][:tenant_name].nil?
  end
end

# input validation methods

def valid_input?(input, type = :str)
  case type
  when :str
    input unless input.strip.empty?
  when :num
    # for matching valid integers & decimal numbers
    input if input.strip.match?(/\A\d+(\.\d+)?\z/)
  end
end

def two_decimals(num)
  return if num.nil?
  format("%.2f", num)
end

def capitalize_name(name)
  return if name.nil?
  name.split.map(&:capitalize).join(" ")
end

# data fetching methods

def load_apartment(id)
  apartment = @storage.find_apartment(id)
  return apartment if apartment

  session[:error] = "The specified property was not found."
  redirect "/"
end

# user authentication methods

def load_user_credentials
  credentials_path = File.expand_path("../users.yml", __FILE__)
  YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.create(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

def require_signed_in_user
  unless session[:username]
    session[:error] = "You must be signed in to do that."
    redirect "/"
  end
end

def user_signed_in?
  session.key?(:username)
end

before do
  @storage = DatabasePersistence.new(logger)
  # @sort_tenants = ["name", "address", "tenants"]
end

get "/" do
  @apartments = @storage.all_apartments
  erb :home
end

get "/view/:id" do
  id = params[:id]
  @apartment = load_apartment(id)
  # @tenants = @storage.load_tenants(id)
  erb :apartment
end

# misc routes

post "/sort" do

end

# new data

get "/new/apartment" do
  erb :new_apartment
end

post "/new/apartment" do
  name = valid_input?(params[:name])
  address = valid_input?(params[:address])

  if name && address
    @storage.new_apartment(name, address)
    session[:success] = "New property added!"
    redirect "/"
  else
    session[:error] = "Please input a valid name and/or address."
    status 422
    session[:name] = name
    session[:address] = address
    erb :new_apartment
  end
end

get "/new/:apartment_id/tenant" do
  @apartment_id = params[:apartment_id]
  session[:name], session[:rent] = '', ''
  erb :new_tenant
end

post "/new/:apartment_id/tenant" do
  name = capitalize_name(valid_input?(params[:name]))
  rent = two_decimals(valid_input?(params[:rent], :num))
  apartment_id = params[:apartment_id]

  if name && rent
    @storage.new_tenant(name, rent, apartment_id)
    session[:success] = "New tenant added!"
    redirect "/view/#{apartment_id}"
  else
    session[:error] = "Please input a valid name and/or rent."
    status 422
    @apartment_id = apartment_id
    session[:name] = name
    session[:rent] = rent
    erb :new_tenant
  end
end

# modify apartment

get "/edit/:apartment_id" do
end

post "/edit/:apartment_id" do
end

post "/delete/:apartment_id" do
  apartment_id = params[:apartment_id]
  @storage.delete_apartment(apartment_id)
end

# modify tenant

get "/edit/:apartment_id/tenant/:tenant_id" do
end

post "/edit/:apartment_id/tenant/:tenant_id" do
end

post "/delete/:apartment_id/tenant/:tenant_id" do
  apartment_id = params[:apartment_id]
  tenant_id = params[:tenant_id]
  @storage.delete_tenant()
end

after do
  @storage.disconnect
end