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
    elsif ip_match body
      ip_request body
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
      body_out = body_input +"=" + decimal_approx(response)
    when "Result"
      body_out = body_input +"=" + result(response)
    when "Plot"
      body_out = indefinite_integral response
    when "VisualRepresentationOfTheIntegral"
      body_out = definite_integral response
    when "Definition:WordData"
      body_out = body_input +"=" + word_data(response)
    when "BasicInformation:MovieData"
      body_out = movie response
    when "CorporateInformationPod:InternetData"
      body_out = corporate_internet response
    when "BasicInformation:PeopleData"
      body_out = people_data response
    else
      body_out = 'response not available'
  end

  body_out
end

def result response
  result = response.find { |pod| pod.title == "Result" }
  result.subpods[0].plaintext
end

def decimal_approx response
  response["DecimalApproximation"].subpods[0].plaintext
end

def indefinite_integral response
  response["IndefiniteIntegral"].subpods[0].plaintext
end

def definite_integral response
  bs = response["Input"].subpods[0].plaintext
  #bs.gsub(/^/, " to ")
end

def ip_match body
  /^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}$/.match(body)
  # if m is nil then no ip address was found else we found an ip address
end


def ip_request(ip_address)

  current_time = Time.now
  timestamp = Time.now.to_i.to_s
  sig = Digest::MD5.hexdigest(NEUSTAR_API_KEY+NEUSTAR_SHARED_SECRET+timestamp)

  request_url = "http://api.neustar.biz/ipi/std/#{NEUSTAR_API_VERSION}/ipinfo/#{ip_address}?apikey=#{NEUSTAR_API_KEY}&sig=#{sig}&format=json"

  url = URI.parse(request_url)
  http = Net::HTTP.new(url.host, url.port)
  request = Net::HTTP::Get.new(url.request_uri)

  response = http.request(request)

  #Probably don't want to use all of the data.
  JSON.load(response.body).to_s
end

def word_data response
  response.pods[1].subpods[0].plaintext
end

def movie response
  response.pods[1].subpods[0].plaintext
end

def corporate_internet response
  response.pods[1].subpods[0].plaintext
end

def people_data response
  facts = response.find { |pod| pod.id == "NotableFacts:PeopleData" }
  response.pods[1].subpods[0].plaintext + facts.subpods[0].plaintext if facts
end


