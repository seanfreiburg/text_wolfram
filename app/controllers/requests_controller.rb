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
    @response = {:from => params["To"],
                 :to => params["From"],
                 :body => body}
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
    process_wolfram_response response

  end
end

def process_wolfram_response response

  body_input = response.pods[0].subpods[0].plaintext
  body_out = ''
  case response.pods[1].id
    when "DecimalApproximation"
      body_out = decimal_approx response
    when "Result"
      body_out = result response
    else
      body_out = "type not availible"
  end

  body_input + "=" +body_out
end

def result response
  result = response.find { |pod| pod.title == "Result" }
  result.subpods[0].plaintext
end

def decimal_approx response
  response["DecimalApproximation"].subpods[0].plaintext
end
