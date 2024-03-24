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

PER_PAGE = 5

# input validation methods

def valid_input?(input, type = :str)
  case type
  when :str
    input unless input.strip.empty?
  when :num
    # for matching valid integers & decimal numbers
    input if input.strip.match?(/\A\d+(\.\d+)?\z/)
  when :usern
    # match for letters and numbers (no spaces)
    input if input.match?(/\A[a-zA-Z0-9]+\z/)
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

def calc_total_pages(total_rows, per_page = PER_PAGE)
  sum = (total_rows.to_f / PER_PAGE).ceil
  sum == 0 ? 1 : sum
end

# session handling methods

def clear_session_values(*keys)
  keys.each do |key|
    session[key] = nil
  end
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
    session[:error] = "Please sign in."
    redirect "/users/signin"
  end
end

def user_signed_in?
  session.key?(:username)
end

before do
  @storage = DatabasePersistence.new(logger)
end

get "/" do
  require_signed_in_user

  @page = (params[:page] || 1).to_i
  offset = (@page - 1) * PER_PAGE

  @apartments = @storage.all_apartments(offset: offset, limit: PER_PAGE)

  total_apartments = @storage.total_apartment_count
  @total_pages = calc_total_pages(total_apartments)

  redirect "/error" unless @page <= @total_pages

  erb :home
end

get "/view/:id" do
  id = params[:id]
  @apartment = @storage.fetch_apartment(id)

  redirect "/error" unless @apartment

  @page = (params[:page] || 1).to_i
  offset = (@page - 1) * PER_PAGE

  @tenants = @storage.all_tenants(offset: offset, limit: PER_PAGE, id: @apartment[:id])
  total_tenants = @storage.total_tenant_count(@apartment[:id])
  @total_pages = calc_total_pages(total_tenants)

  redirect "/error" unless @page <= @total_pages

  erb :apartment
end

get "/error" do
  session[:error] = "404 Not Found - Please make sure the URL is valid"
  erb :not_found
end

# new data

get "/new/apartment" do
  clear_session_values(:name, :address)
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
    session[:error] = "Please input a valid name and address."
    status 422

    session[:name] = name
    session[:address] = address
    erb :new_apartment
  end
end

get "/new/:apartment_id/tenant" do
  clear_session_values(:name, :rent)
  apartment = @storage.fetch_apartment(params[:apartment_id])
  
  redirect "/error" unless apartment
  
  @apartment_id = apartment[:id]

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
    session[:error] = "Please input a valid name and rent."
    status 422

    @apartment_id = apartment_id
    session[:name] = name
    session[:rent] = rent
    erb :new_tenant
  end
end

# modify apartment

get "/edit/:apartment_id" do
  clear_session_values(:name, :address)

  @id = params[:apartment_id]
  apartment = @storage.fetch_apartment(@id)

  redirect "/error" unless apartment

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
    session[:error] = "Please input a valid name and address."
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

  session[:success] = "Property deleted successfully!"
  redirect "/"
end

# modify tenant

get "/edit/:apartment_id/tenant/:tenant_id" do
  clear_session_values(:name, :rent)
  @tenant_id = params[:tenant_id]
  @apartment_id = params[:apartment_id]
  tenant = @storage.fetch_tenant(@tenant_id, @apartment_id)

  redirect "/error" unless tenant

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
    session[:error] = "Please input a valid name and rent."
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

  session[:success] = "Tenant deleted successfuly!"
  redirect "/view/#{apartment_id}"
end

# user sign in

get "/users/signin" do
  clear_session_values(:username_input, :password)
  erb :signin
end

post "/users/signin" do
  username = valid_input?(params[:username])
  password = valid_input?(params[:password])

  if valid_credentials?(username, password)
    session[:username] = username
    session[:success] = "Welcome #{username}!"
    redirect "/"
  else
    session[:error] = "Invalid username or password. Try again."
    status 422

    session[:username_input] = username
    erb :signin
  end
end

# user sign up

get "/users/signup" do
  clear_session_values(:username_input, :password)
  erb :signup
end

post "/users/signup" do
  credentials = load_user_credentials
  username = valid_input?(params[:username], :usern)
  password = valid_input?(params[:password])
  confirm_password = params[:c_password]

  if !username
    session[:error] = "Username should only contain letter and numbers!"
    status 422
    erb :signup
  elsif password != confirm_password
    session[:error] = "Passwords do not match. Please confirm password!"
    status 422

    session[:username_input] = username
    erb :signup
  else
    credentials[username] = password
    File.open("./users.yml", "w") { |f| f.write(YAML.dump(credentials)) }

    session[:username] = username
    session[:success] = "Account created successfully!"
    redirect "/"
  end
end

# user sign out

post "/users/signout" do
  session.delete(:username)
  session[:success] = "You have been signed out."
  redirect "/users/signin"
end

# teardown code

after do
  @storage.disconnect
end