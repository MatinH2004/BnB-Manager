# BnB Manager App

## Intro
This project is a comprehensive apartment rental management application built using Sinatra, ERB templates, PostgreSQL, and session management.

It allows users to efficiently track apartment buildings, rents, and primary tenants for each apartment within the buildings.

The app incorporates essential features for managing rental properties, including user authentication and encrypting user passwords to ensure data security.

With a user-friendly interface and robust functionality, this app simplifies the process of managing apartment rentals effectively.

## Getting Started

Before getting started, make sure you have the following installed on your machine:
- Ruby (3.2.0)
- PostgreSQL v14.10 / pg (1.5.6, 1.5.5)
- Safari (17.2.1) / Chrome (122.0.6261.129)

Gems:
- sinatra (4.0.0, 3.1.0)
- sinatra-contrib (4.0.0, 3.1.0)
- erubis (2.7.0)
- rackup (2.1)
- bcrypt (3.1.20)
- puma (6.4.2, 6.4.0)
- pg (1.5.6, 1.5.5)
- bundler (2.4.21, 2.4.15, 1.12.5)

1. To get started, make sure the `require "bundler/setup"` is at the top of `app.rb` file to set up the Ruby environment and load the necessary gems. Then run the following code to install the applications's dependancies:
```bash
bundle install
```

2. Next, create a database, and import the schema and seed data:
```bash
createdb bnb_manager

psql -d bnb_manager < schema.sql
```

3. If you choose a different name for your database, makesure you use the same name when connecting in the `database_api.rb` file.

4. When ready, run the following to start the application and it should be available on `http://localhost:4567`.
```bash
bundle exec ruby app.rb
```

5. When you open the page, you will be prompted to sign in or sign up for an account. Feel free to use the following user credential to sign in:
```yaml
developer: letmein
```

## Fulfilled Requirements

### Database Tables
- The app uses 2 primary database tables in a one to many relationship (1:M), as a tenant can have one apartment, but an apartment can have many tenants.

### CRUD Capabilities
- The app provides CRUD capabilities both for the apartments and the tenants, as you are able to create, view, edit, and delete any apartment or tenant.
  - When an apartment with tenants is deleted, the tenants with the corresponding `apartment_id` will also be deleted, as I defined `ON DELETE CASCADE` for that column's foreign key.

- All data updates are immediately reflected both in the application and the database.

### Pagination
- Pagination is implemented for pages that display more than 5 rows of data, using query strings. The `PER_PAGE` constant limits the number of rows that is output, and within the routes the offset and total number of pages values are calculated. If the user inputs an invalid page number, they are redirected to the 404 Not Found Page.

### Sorting Data
- Both apartments and tenants data are sorted by their names, in alphabetical order. The rows are sorted accordingly when data is manipulated.

### Flash Messages
- I have setup 2 flash messages. One for successful actions and one for errors, `session[:success]` and `session[:error]`.
  - Bad user input, invalid URLs, unsuccessful user authentication, and non-existent pages (404) trigger the `session[:error]` flash message with an appropriate error message.
  - When a user successfuly signs in/out, creates/edits/deletes an apartment/tenant, and enters any valid input, the `session[:success]` flash message is displayed with the appropriate message.

### Input Validation
- When inputting data, invalid data is cleared, but valid data is not, so the user does not have to re-enter it.
  - I achieved this using session values.
  - For example, in the `post "/new/apartment"` route, my `valid_input?` validator returns the string object passed in if it's valid, or returns `nil` otherwise. Then I assign these values to `session[:name]` and `session[:address]`, which are called in the `value=""` attribute of the `<input>` elements. So, if the data is valid, it is shown in the input box, if the data is not valid, the session value references `nil`, which is not displayed in the input box.

- All HTML input is escaped, and all SQL queries are called with the `#exec_params` method.

### User Authentication
- The app requires sign in authentication for all operations.
  - This is achieved through the use of `require_signed_in_user` method, called in the primary `get` routes, which checks whether `session[:username]` exists.
  - When a user signs in successfully, their username is assigned to `session[:username]`, and upon signing out, the `:username` key is deleted from the session.
  - If a user enters an URL for a page without signing in first, the sign in page is displayed, and the requested url is saved into `session[:request_path]`, by calling `path_info` on the `request` object. Upon successful authentication, the app redirects the user to the path in `session[:request_path]` or to `"/"` if no path is present. (`app.rb`, line 313)

- Authentication passwords are encrypted using the `BCrypt` gem. As you can see in the `post "/users/signup"` route, a hashed password is generated (`app.rb`, line 351), and user data is saved into the `users.yml` yaml file.

## Revisions

### App Configuration
"There's a lacking detail in the configuration of your app or the instruction for running of your app"
  - The configuration detail missing was `require "bundler/setup"` missing at the top of `app.rb`, which sets up the enviroment for Ruby and properly loads the required gems. Since this is defined now, we must run the app using `bundle exec ruby app.rb`.

### Require Signed In User
"I was able to delete a property without being logged in with `curl -X POST -iv -d "" 'http://localhost:4567/delete/3'`"
  - I fixed this issue by adding `required_signed_in_user` to the POST routes that delete data. Other POST routes won't need this, because they need to validate user input before modifying data, so logged out users won't be able to make a POST request with `curl`.