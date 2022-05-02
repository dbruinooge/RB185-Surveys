require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require "bcrypt"
require "pry"

require_relative "lib/database_persistence.rb"

# check how to set a better session secret
configure do
  enable :sessions
  set :session_secret, "secret"
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "lib/database_persistence.rb"
end

before do
  @storage = DatabasePersistence.new
end

helpers do
  def number_of_questions(survey_id)
    @storage.find_number_of_questions(survey_id)
  end
end

def require_signed_in_user
  session[:message] = "You must be signed in to do that."
  redirect "/"
end

def valid_credentials?(username, password)
  if @storage.username_exists?(username)
    # bcrypt_password = BCrypt::Password.new(@storage.find_password(username))
    database_password = @storage.find_password(username)
    database_password == password
  else
    false
  end
end

def error_for_survey_title(title)
  if survey_title_already_exists?(title)
    "Sorry, a survey with that title already exists."
  elsif title == ""
    "Title must be between 1 and 25 characters."
  end
end

def error_for_signup(username, password1, password2)
  if username_already_exists?(username)
    "Sorry, that username is already taken."
  elsif password1 != password2
    "Passwords do not match."
  end
end

def username_already_exists?(username)
  @storage.find_user_id(username)
end

def survey_title_already_exists?(title)
  @storage.find_survey_id(title)
end

def user_took_survey?(survey_id)
  user_id = @storage.find_user_id(session[:username])
  @storage.find_taken_record(user_id, survey_id)
end

# View the index
get "/" do
  @surveys = @storage.find_all_surveys
  erb :home
end

# View the signin page
get "/users/signin" do
  erb :signin
end

# Sign in to the site
post "/users/signin" do
  username = params[:username]
  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid credentials."
    status 422
    erb :signin
  end
end

# Sign out from the site
post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end

# View a survey summary
get "/surveys/:survey_id" do
  require_signed_in_user unless session[:username]
  survey_id = params[:survey_id].to_i
  @survey = @storage.find_survey(survey_id)
  erb :survey
end

# View a survey's questions
get "/surveys/take/:survey_id" do
  survey_id = params[:survey_id].to_i
  @survey = @storage.find_survey(survey_id)
  if user_took_survey?(survey_id)
    session[:message] = "Sorry, you've already taken this survey."
    erb :survey
  else
    @questions_choices = @storage.find_survey_items(survey_id)
    erb :take_survey
  end
end

# Submit survey choices
post "/surveys/take/:survey_id" do
  survey_id = params.delete(:survey_id)
  user_id = @storage.find_user_id(session[:username])
  @storage.record_choices(params)
  @storage.record_user_took_survey(user_id, survey_id)
  session[:message] = "Thanks for taking the survey!"
  redirect "/"
end

# View survey maker screen
get "/make_survey" do
  require_signed_in_user unless session[:username]
  erb :make_survey
end

# Make a new survey
post "/make_survey" do
  title = params[:title]
  error = error_for_survey_title(title)
  if error
    session[:message] = error
    erb :make_survey
  else
    @storage.add_survey(title, session[:username])
    @storage.add_survey_items(params)
    session[:message] = "Survey successfully created."
    redirect "/"
  end
end

# View user signup page
get "/users/signup" do
  erb :signup
end

post "/users/signup" do
  username = params[:username]
  password1 = params[:password1]
  password2 = params[:password2]
  error = error_for_signup(username, password1, password2)
  if error
    session[:message] = error
    erb :signup
  else
    @storage.add_user(username, password1)
    session[:message] = "Welcome! Please sign in to your account."
    redirect "/"
  end
end