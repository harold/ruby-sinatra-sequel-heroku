STDOUT.sync = true
require "sinatra"
require "sequel"
require "haml"
require "rack-flash"

set :haml, :format => :html5

enable :sessions
use Rack::Flash

COOKIE_NAME = "site-login"

configure do
	DB = Sequel.connect( ENV["DATABASE_URL"] || "sqlite://my.db" )
	require "./models"
end

before do
	path = request.path_info
	unless path[/login|signup/i] or path[/(ico|css|js|png)$/]
		cookie = request.cookies[COOKIE_NAME]
		if cookie
			email, password = cookie.split("::")
			@user = User[email:email, password:password]
		end
		unless @user
			redirect "/login"
		end
	end
end

template :layout do
	IO.read "views/layout.haml"
end

get "/" do
	haml :index
end

get "/login/?" do
	@custom_css = "/css/login.css"
	haml :login
end

post "/login/?" do
	email    = params[:email]
	password = hash_password( params[:password])
	@user    = User[email:email, password:password]
	if @user
		set_cookie(email,password)
	else
		flash[:notice] = "Login Failed - Please try again..."
	end
	redirect "/"
end

get "/signup/?" do
	@custom_css = "/css/login.css"
	haml :signup
end

post "/signup/?" do
	if "TODO: Site code..." != params[:signupcode] then
		flash[:notice] = "Signup Failed - Please try again..."
		redirect "/signup"
	end

	email    = params[:email]
	password = hash_password( params[:password] )
	@user = User[email:email]
	
	if @user
		redirect "/"
	else
		User.create(email:email,password:password)
		@user = User[email:email,password:password]
		set_cookie(email,password)
		redirect "/"
	end
end

get "/logout/?" do
	set_cookie("","")
	redirect "/"
end

helpers do
	def hash_password(password)
		salt = "yomamaain'tgotnorainbowtableforthismother"
		Digest::SHA1.hexdigest(password+salt)
	end
	
	def set_cookie(email, password)
		cookie_value = "#{email}::#{password}"
		response.set_cookie( COOKIE_NAME, {expires:Time.now+(10**6), value:cookie_value} )
	end
end
