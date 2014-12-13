require 'rack'
require 'sinatra'
require 'orchestrate'
require 'jwt'

configure do
	set :erb, layout: :layout
end

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
	# puts note
	password = JWT.encode({password: params[:password]}, 'nothackable')
	# puts password

	saved = notes << {note: note, pass: password}
	ref = saved.id.gsub('notes/', '')

	redirect "/note/#{ref}"
end

get '/note/:id' do
	id = params[:id]
	note = notes[id].value
	@password = JWT.decode(note["pass"], 'nothackable')[0]["password"]
	@ref= notes[id].id.gsub('notes/', '')



	erb :secure
end

get '/secure/note/:id' do
	id = params[:id]
	@note = notes[id].value

	erb :note
end
