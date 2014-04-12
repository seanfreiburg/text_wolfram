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
    process_wolfram_response response

  end
end

def process_wolfram_response response

  text = try_result response
  if text == null
    try_decimal_approx response
  end
end

def try_result response
  begin
    input = response["Input"] # Get the input interpretation pod.
    result = response.find { |pod| pod.title == "Result" }
    "#{input.subpods[0].plaintext} = \n #{result.subpods[0].plaintext}"
  rescue
    null
  end

end

def try_decimal_approx response
  begin
    input = response["Input"].subpods[0].plaintext
    approx = response["DecimalApproximation"].subpods[0].plaintext
    "#{input} = #{approx}"
  rescue
    null
  end
end
