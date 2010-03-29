# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_winnower_session',
  :secret      => '1b74eb5adfdcc2d485d81a04a627cf5723d67bc5c734c8dfccbd5afdba1ce45e434e52cbf3ed9813f0d4ccf9fedfad6ec814f7dfe115637255198d25c4de80ef'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
