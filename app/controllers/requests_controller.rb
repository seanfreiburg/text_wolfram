class RequestsController < ApplicationController

  def index
    puts "Recieved request"

    @client = Twilio::REST::Client.new(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)


    body = wolfram_request(params["Body"])
    @client.account.messages.create(
        :from => params["To"],
        :to => params["From"],
        :body => body
    )
  end


  def wolfram_request body
    options = {"format" => "plaintext"} # see the reference appendix in the documentation.[1]

    client = WolframAlpha::Client.new WOLFRAM_API_KEY, options
    response = client.query "5 largest countries"
    input = response["Input"] # Get the input interpretation pod.
    result = response.find { |pod| pod.title == "Result" }

  end
end
