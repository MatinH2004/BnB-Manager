# BnB Manager App

## Intro
This project is a comprehensive apartment rental management application built using Sinatra, ERB templates, PostgreSQL, and session management.

It allows users to efficiently track apartment buildings, rents, and primary tenants for each apartment within the buildings.

The app incorporates essential features for managing rental properties, including user authentication using the `yaml` gem for storing authentication information securely and `BCrypt` for encrypting user passwords to ensure data security.

With a user-friendly interface and robust functionality, this app simplifies the process of managing apartment rentals effectively.

## Getting Started

Before getting started, make sure you have the following installed on your machine:
- Ruby (3.2.0)
- sinatra (4.0.0, 3.1.0)
- PostgreSQL v14.10 / pg (1.5.6, 1.5.5)
- Rackup (2.1)
- Safari (17.2.1) / Chrome (122.0.6261.129)

1. To get started, install the app's dependancies:
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
ruby app.rb
```

5. When you open the page, you will be prompted to sign in or sign up for an account. Feel free to use this sign on details:
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
- I have setup 2 flash messages. One for successful actions and one for incorrect actions, `session[:success]` and `session[:error]`, respectively. 
  - Bad user input, invalid URLs, unsuccessful user authentication, and non-existent pages (404) trigger the `session[:error]` flash message.
  - When a user successfuly signs in/out, creates/edits/deletes an apartment/tenant, and enters any valid input, the `session[:success]` flash message is displayed.

### Input Validation
- When inputting data, invalid data is cleared, however valid data is not, as per the requirement, "the make the user re-enter valid data".
  - I achieved this using session values.
  - For example, in the `post "/new/apartment"` route, my `valid_input?` validator returns the string object passed in if it's valid, or returns `nil` otherwise. Then I assign these values to `session[:name]` and `session[:address]`, which are present in the `value` attribute of the `<input>` elements. So, if the data is valid, it is shown in the input box, if the data is not valid, the session value references `nil`, which is not displayed in the input box.

### User Authentication
- The app requires sign in authentication for all operations.
  - This is achieved through the use of `require_signed_in_user` method, called in the primary `get` routes.
  - If a user enters an URL for a page without signing in first, the sign in page is displayed, and the requested url is saved into `session[:request_path]`, by calling `path_info` on the `request` object. Upon successful authentication, the app redirects the user to the path in `session[:request_path]` or to `"/"` if no path is present. (`app.rb`, line 313)

- Authentication passwords are encrypted using the `BCrypt` gem. As you can see in the `post "/users/signup"` route, a hashed password is generated (`app.rb`, line 351), and user data is saved into the `users.yml` yaml file.