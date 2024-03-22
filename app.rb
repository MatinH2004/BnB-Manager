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
    @tenants.first.values.compact.empty?
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
  PER_PAGE = 5
end

get "/" do
  @page = (params[:page] || 1).to_i
  offset = (@page - 1) * PER_PAGE

  @apartments = @storage.all_apartments(offset: offset, limit: PER_PAGE)
  total_apartments = @storage.total_apartment_count
  @total_pages = (total_apartments.to_f / PER_PAGE).ceil

  erb :home
end

get "/view/:id" do
  id = params[:id]
  @apartment = @storage.fetch_apartment(id)

  @page = (params[:page] || 1).to_i
  offset = (@page - 1) * PER_PAGE

  @tenants = @storage.all_tenants(offset: offset, limit: PER_PAGE, id: @apartment[:id])
  total_tenants = @storage.total_tenant_count(@apartment[:id])
  @total_pages = (total_tenants.to_f / PER_PAGE).ceil
  # binding.pry
  erb :apartment
end

# new data

get "/new/apartment" do
  session[:name], session[:address] = '', ''
  erb :new_apartment
end

post "/new/apartment" do
  name = capitalize_name(valid_input?(params[:name]))
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
  session[:name], session[:rent] = '', ''
  @apartment_id = params[:apartment_id]
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
  session[:name], session[:address] = '', ''

  @id = params[:apartment_id]
  apartment = @storage.fetch_apartment(@id)

  session[:name] = apartment[:name]
  session[:address] = apartment[:address]

  erb :edit_apartment
end

post "/edit/:apartment_id" do
  apartment_id = params[:apartment_id]
  name = valid_input?(params[:name])
  address = valid_input?(params[:address])

  if name && address
    @storage.edit_apartment(name, address, apartment_id)
    session[:success] = "Property details have been updated!"
    redirect "/"
  else
    session[:error] = "Please input a valid name and/or address."
    status 422

    @id = apartment_id
    session[:name] = name
    session[:address] = address
    erb :edit_apartment
  end
end

post "/delete/:apartment_id" do
  apartment_id = params[:apartment_id]
  @storage.delete_apartment(apartment_id)
  redirect "/"
end

# modify tenant

get "/edit/:apartment_id/tenant/:tenant_id" do
  session[:name], session[:rent] = '', ''
  @tenant_id = params[:tenant_id]
  @apartment_id = params[:apartment_id]
  tenant = @storage.fetch_tenant(@tenant_id)

  session[:name] = tenant[:name]
  session[:rent] = tenant[:rent]

  erb :edit_tenant
end

post "/edit/:apartment_id/tenant/:tenant_id" do
  apartment_id = params[:apartment_id]
  tenant_id = params[:tenant_id]

  name = capitalize_name(valid_input?(params[:name]))
  rent = two_decimals(valid_input?(params[:rent], :num))

  if name && rent
    @storage.edit_tenant(name, rent, tenant_id)
    session[:success] = "Tenant details have been updated!"
    redirect "/view/#{apartment_id}"
  else
    session[:error] = "Please input a valid name and/or address."
    status 422

    @apartment_id = apartment_id
    @tenant_id = tenant_id
    session[:name] = name
    session[:rent] = rent
    erb :edit_tenant
  end
end

post "/delete/:apartment_id/tenant/:tenant_id" do
  apartment_id = params[:apartment_id]
  tenant_id = params[:tenant_id]
  @storage.delete_tenant(apartment_id, tenant_id)
  redirect "/view/#{apartment_id}"
end

# user authentication - below routes not tested

get "/users/signin" do
  session[:username], session[:password] = '', ''
  erb :signin
end

post "/users/signin" do
  credentials = load_user_credentials
  username, password = params[:username], params[:password]

  if valid_credentials?(username, password)
    session[:username] = username
    session[:success] = "Welcome!"
    redirect "/"
  else
    session[:error] = "Invalid username and/or password. Try again."
    status 422
    erb :signin
  end
end

#

get "/users/signup" do
  session[:username], session[:password] = '', ''
  erb :signup
end

post "/users/signup" do
  credentials = load_user_credentials
  session[:username] = params[:username]
  password = params[:password]
  confirm_password = params[:c_password]

  if !valid_input?(session[:username])
    session[:error] = "Username cannot be empty!"
    status 422
    erb :signup
  elsif password != confirm_password
    session[:error] = "Passwords do not match. Please confirm password!"
    status 422
    erb :signup
  else
    credentials[session[:username]] = password
    File.open("./users.yml", "w") { |f| f.write(YAML.dump(credentials)) }
    session[:success] = "Account created successfully!"
    redirect "/"
  end
end

#

post "/users/signout" do

end

# teardown code

after do
  @storage.disconnect
end