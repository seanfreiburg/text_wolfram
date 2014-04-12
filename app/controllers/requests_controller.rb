class RequestsController < ApplicationController

  def index
    puts "Recieved request"

    @client = Twilio::REST::Client.new(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)


    body = process_request(params["Body"])
    @client.account.messages.create(
        :from => params["To"],
        :to => params["From"],
        :body => body
    )
  end


  def process_request body
    if body.downcase == "is my tractor sexy?"
      "yes"
    else
      wolfram_request body
    end
  end
  def wolfram_request body
    options = {"format" => "plaintext"} # see the reference appendix in the documentation.[1]

    client = WolframAlpha::Client.new WOLFRAM_API_KEY, options
    response = client.query body
    input = response["Input"] # Get the input interpretation pod.

    result = response.find { |pod| pod.title == "Result" }
    "#{input.subpods[0].plaintext} = #{result.subpods[0].plaintext}"

  end
end
