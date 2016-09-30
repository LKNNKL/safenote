require 'rack'
require 'sinatra'
require 'orchestrate'
require 'jwt'
require 'sequel'
require 'bcrypt'
require 'sqlite3' if development?
require 'pg' if production?

configure do
	set :erb, layout: :layout
	enable :sessions
end

DB = Sequel.connect(ENV['DATABASE_URL']) || Sequel.sqlite('./development.sqlite3')

DB.create_table? :notes do
	String :uid
	String :content, :text => true
	String :password
end

class Note < Sequel::Model
end

def rand_uid(length)
  rand(36**length).to_s(36)
end

# app = Orchestrate::Application.new('6e965f04-d2be-4fab-aa92-a5cf63be50b4')
# notes = app[:notes]

get '/' do
	erb :index
end

get '/new' do
	erb :new
end

post '/new' do
	if params[:note] == '' || !params[:password] == ''
		redirect '/new'
	end
	content = params[:note]
	# password = JWT.encode({password: params[:password]}, 'nothackable')
	password = BCrypt::Password.create(params[:password])

	# saved = notes << {note: note, pass: password}
	note = Note.create(
			:uid => rand_uid(6),
			:content => content,
			:password => password
			)

	# ref = saved.id.gsub('notes/', '')
	redirect "/note/#{note.uid}"
end

get '/note/:uid' do
	@uid = params[:uid]
	erb :secure
end

post '/verify/:uid' do
	uid = params[:uid]
	password = params[:password]
	# note = notes[uid].value
	notes = Note.where(:uid => uid)
	note = notes.first
	actual_password = BCrypt::Password.new(note.password)
	if actual_password == password
		# puts "Note is verified"
		session[:verified] = true
		redirect "/secure/note/#{uid}"
	else
		# puts "Note is not verified: #{uid}"
		redirect "/note/#{uid}"
	end
end

get '/secure/note/:uid' do
	uid = params[:uid]
	if session[:verified]
		puts "success on secure page!"
		@note = Note.where(:uid => uid).first
		session[:verified] = false
		erb :note
	else
		puts "no success, redirecting back to note..."
		redirect "/note/#{uid}"
	end
end
