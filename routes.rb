require 'sinatra/base'
require 'json'

class Routes < Sinatra::Base

  here = File.dirname(__FILE__)
  SYNC_SCRIPT = "#{here}/script/update.sh"
  GO_AWAY_COMMENT = "Be gone, foul creature of the internet."
  THANK_YOU_COMMENT = "Thanks! You beautiful soul you."
  def rude_comment
    GO_AWAY_COMMENT
  end
  
  configure :development do
  end
  post '/update' do
    begin
      payload = params[:payload]
      return rude_comment if payload.nil?

      push = JSON.parse(payload)
      system(SYNC_SCRIPT)
      THANK_YOU_COMMENT
    rescue
      "error."
    end
  end

  get '/' do
    erb :home
  end
  not_found do
    'This is nowhere to be found'
  end
  error do
    'Sorry there was a nasty error - ' + env['sinatra.error'].name
  end
end
