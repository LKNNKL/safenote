require 'rack'
require 'sinatra'
require 'orchestrate'
require 'jwt'

configure do
	set :erb, layout: :layout
	enable :sessions
end

DB = Sequel.sqlite('./development.sqlite3') || Sequel.connect(ENV['DATABASE_URL'])

app = Orchestrate::Application.new('6e965f04-d2be-4fab-aa92-a5cf63be50b4')
notes = app[:notes]

get '/' do
	erb :index
end

get '/new' do
	erb :new
end

post '/new' do
	note = params[:note]
	password = JWT.encode({password: params[:password]}, 'nothackable')

	saved = notes << {note: note, pass: password}
	ref = saved.id.gsub('notes/', '')

	redirect "/note/#{ref}"
end

get '/note/:id' do
	id = params[:id]
	note = notes[id].value
	@ref = notes[id].id.gsub('notes/', '')
  # @ref = 'lol'
	erb :secure
end

get '/verify/:id' do
	id = params[:id]
	pass = params[:pass]
	note = notes[id].value
	if pass == JWT.decode(note["pass"], 'nothackable')[0]["password"] 
		puts "Note is verified! #{id}"
		session[:verified] = true
		redirect "/secure/note/#{id}"
	else
		puts "Note is not verified: #{id}"
		redirect "/note/#{id}"
	end
end

get '/secure/note/:id' do
	id = params[:id]
	if session[:verified] == true
		puts "success on secure page!"
		@note = notes[id].value
		session[:verified] = false
		erb :note
	else
		puts "no success, redirecting back to note..."
		redirect "/note/#{id}"
	end
end
