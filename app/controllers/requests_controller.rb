class RequestsController < ApplicationController

  def index
    puts "Recieved request"

    @client = Twilio::REST::Client.new(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
    @client.account.messages.create(
        :from => params["To"],
        :to => params["From"],
        :body => params["Body"]
    )
  end
end
