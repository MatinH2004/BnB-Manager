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
    # for matching decimal numbers
    input if input.match?(/\A\d+(\.\d+)?\z/)
  end
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
    session[:error] = "Please input a valid name or address."
    status 422
    session[:name] = name
    session[:address] = address
    erb :new_apartment
  end
end

get "/new/:apartment_id/tenant" do
  erb :new_tenant
end

post "/new/tenant" do

end

# modify apartment

get "/edit/:apartment_id" do

end

post "/edit/:apartment_id" do

end

post "/delete/:apartment_id" do

end

# modify tenant

get "/edit/:apartment_id/tenant/:tenant_id" do

end

post "/edit/:apartment_id/tenant/:tenant_id" do

end

post "/delete/:apartment_id/tenant/:tenant_id" do

end

after do
  @storage.disconnect
end