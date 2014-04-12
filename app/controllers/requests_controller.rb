class RequestsController < ApplicationController

  def index
    puts "Recieved request"

    @client = Twilio::REST::Client.new(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
    @client.account.messages.create(
        :from => '+12173344307',
        :to => '+12176173798',
        :body => 'Hey there!'
    )
  end
end
