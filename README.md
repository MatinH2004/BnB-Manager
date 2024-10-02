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
