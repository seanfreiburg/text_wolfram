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

    elsif body.downcase == "help"
      "The following are acceptable queries to text:\n\n192.168.0.1 (IP Addresses)\n\nValid Wolfram|Alpha queries\n\nDirections in the following form:\ndirections (required keyword)\nstart address\nend address"
    elif body.downcase.include? "destination"
      des,start_ad, end_ad = body.split(",")
      directions(start_ad,end_ad)
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
    when "Quote"
      body_out = quote response
    when "PeriodicTableLocation:ElementData"
      body_out = element response
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

  timestamp = Time.now.to_i.to_s
  sig = Digest::MD5.hexdigest(API_KEY+SHARED_SECRET+timestamp)

  request_url = "http://api.neustar.biz/ipi/std/#{API_VERSION}/ipinfo/#{ip_address}?apikey=#{API_KEY}&sig=#{sig}&format=json"

  url = URI.parse(request_url)
  http = Net::HTTP.new(url.host, url.port)
  request = Net::HTTP::Get.new(url.request_uri)

  response = http.request(request)

  hash = JSON.load(response.body)

  if not hash['gds_error'].nil? then
    body = hash['gds_error']['message']
  else
    body = info_check("IP Address: ", hash['ipinfo']['ip_address'], true)+
        info_check("Organization: ", hash['ipinfo']['Network']['organization'], true)+
        info_check("Carrier: ", hash['ipinfo']['Network']['carrier'], true)+
        info_check("Latitude: ", hash['ipinfo']['Location']['latitude'], true)+
        info_check("Longitude: ", hash['ipinfo']['Location']['longitude'], true)+
        info_check("Country: ", hash['ipinfo']['Location']['CountryData']['country'], true)+
        info_check("State: ", hash['ipinfo']['Location']['StateData']['state'], true)+
        info_check("City: ", hash['ipinfo']['Location']['CityData']['city'], false)
    if body.length < 30 then
      body = "No IP mapping exists for [#{ip_address}]"
    end
  end
  body

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
  facts_sec = response.find { |pod| pod.id == "NotableFacts:PeopleData" }
  facts = facts_sec.subpods[0].plaintext if facts_sec
  facts = '' if facts.nil?
  response.pods[1].subpods[0].plaintext + facts
end

def quote response
  quote = (response.find { |pod| pod.id == "Quote" }).subpods[0].plaintext
  company_info = (response.find { |pod| pod.id == "CompanyInformation" }).subpods[0].plaintext
  body = ''
  body += quote.to_s + '\n'
  body += company_info.to_s
end


def element response
  response.pods[0].subpods[0].plaintext + (response.find { |pod| pod.id == "Elemental2:ElementData" }).subpods[0].plaintext
end


def info_check(title_text, json_object, newline)
  if json_object.nil?
  then
    ""
  else
    title_text+json_object.to_s+ if newline then
                                   "\n"
                                 else
                                   ""
                                 end
  end
end

def directions(source,destination)

  url = URI("https://maps.googleapis.com/maps/api/directions/json")
  params = { :sensor => false, :origin => source, :destination => destination, :key => "AIzaSyBvbZUMkNxFl5lvHp7U8763z8WsWtmD1Kw" }

  url.query = URI.encode_www_form(params)
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(url.request_uri)

  response = http.request(request)

  hash = JSON.load(response.body)
  #print hash
  start_add = hash['routes'][0]['legs'][0]['start_address']
  end_add = hash['routes'][0]['legs'][0]['end_address']
  distance = hash['routes'][0]['legs'][0]['distance']['text']
  time = hash['routes'][0]['legs'][0]['duration']['text']
  body = "From: #{start_add}\nTo: #{end_add}\nDistance: #{distance}\nTime: #{time}\nDirections:\n"
  for step in hash['routes'][0]['legs'][0]['steps']
    body += " "+step['html_instructions']+"\n".encode("UTF-8")
  end
  body.gsub(%r{</?[^>]+?>}, '').gsub(/^(.*)(\S+)(?=Passing)/) {|s| s + ' '}.gsub(/^(.*)(\S+)(?=Entering)/) {|s| s + ' '}.gsub(/^(.*)(\S+)(?=Partial)/) {|s| s + ' '}.gsub(/^(.*)(\S+)(?=hToll)/) {|s| s + ' '}.gsub(/^(.*)(\S+)(?=Destination)/) {|s| s + ' '}.gsub(/^(.*)(\S+)(?=Continue)/) {|s| s + ' '}
end
