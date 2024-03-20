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

# data fetching methods

def load_apartment(id)
  apartment = @storage.find_apartment(id)
  return apartment if apartment

  session[:message] = "The specified property was not found."
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
    session[:message] = "You must be signed in to do that."
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
  erb :apartment
end

# misc routes

post "/sort" do

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