require 'nokogiri'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'open-uri'
require 'json'
require 'net/http'
require 'uri'
require 'erb'
require 'dotenv/load'

# --- Backend (GPT Interaction - Now includes scraping) ---

def get_problem_data
  api_key = ENV['OPENAI_API_KEY']
  return nil unless api_key

  uri = URI('https://api.openai.com/v1/chat/completions')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path, {
    'Content-Type' => 'application/json',
    'Authorization' => "Bearer #{api_key}"
  })

  urls_to_scrape = [
    'https://www.unrefugees.org/emergencies/',
    'https://www.thenewhumanitarian.org/conflict',
    'https://www.aljazeera.com/tag/humanitarian-crises/'
  ]

  prompt = "Scrape these websites for a list of relevant issues that a user can donate to, stop running after finding 18 causes, and take one cause from each website and then move to the next website and repeat after you have taken a cause from each website: #{urls_to_scrape.join(' ')}. Extract the name, a short description, link for the article and a google search query to find an image for each cause. Return only the JSON format in plain raw text without using a codebox with ``` and use double quotes for all values in a JSON array: [{\"name\": \"\", \"description\": \"\", \"link\": \"\", \"image_query\": \"\"}, {\"name\": \"\", \"description\": \"\", \"link\": \"\", \"image_query\": \"\"}, ...]"

  request.body = {
    model: 'gpt-4o-mini',
    messages: [{ role: 'user', content: prompt }]
  }.to_json

  response = http.request(request)

  if response.is_a?(Net::HTTPSuccess)
    begin
      gpt_content = JSON.parse(response.body)['choices'][0]['message']['content']
      puts "GPT-4 Content: #{gpt_content}"
      parsed_problems_data = JSON.parse(gpt_content)
      puts "GPT-4 JSON Response: #{parsed_problems_data.inspect}"
      parsed_problems_data
    rescue JSON::ParserError => e
      puts "GPT response parsing error: #{e.message}"
      puts "Problematic GPT Content: #{gpt_content}"
      nil
    end
  else
    puts "GPT API error: #{response.code} #{response.message}"
    nil
  end
end

def get_image_url(query)
  api_key = ENV['GOOGLE_SEARCH_API']
  cse_id  = ENV['CSE_ID']

  return "[https://picsum.photos/200/200](https://picsum.photos/200/200)" unless api_key && cse_id

  uri = URI("https://www.googleapis.com/customsearch/v1?key=#{api_key}&cx=#{cse_id}&q=#{URI.encode_www_form_component(query)}&searchType=image")
  puts "Fetching image for query: #{query}"

  begin
    response = Net::HTTP.get(uri)
    json = JSON.parse(response)
    image_url = json['items']&.first&.dig('link') || "[https://picsum.photos/200/200](https://picsum.photos/200/200)"
    puts "Image URL: #{image_url}"
    image_url
  rescue StandardError => e
    puts "Error fetching image: #{e.message}"
    "[https://picsum.photos/200/200](https://picsum.photos/200/200)"
  end
end

def process_problems(problems_data)
  problems = []
  problems_data&.each do |problem|
    puts "Processing problem: #{problem['name']}"
    #sleep 10 # Be mindful of API rate limits

    image_url = get_image_url(problem['image_query'])

    problems << {
      name: problem['name'],
      description: problem['description'],
      image_url: image_url,
      link: problem['link'] # Since we removed scraping individual article links
    }
  end
  puts "Final Problems List: #{problems.inspect}"
  problems
end

# --- Frontend (Sinatra Server) ---

set :port, 4567

get '/' do
  puts "Starting problem extraction pipeline (GPT-driven)..."

  problems_data = get_problem_data
  @problems = process_problems(problems_data)

  erb :index
end

post '/donate/:problem_name' do
  problem_name = params[:problem_name]
  "Donation processed for #{problem_name}"
end

get '/claim/:problem_name' do
  problem_name = params[:problem_name]
  "Claim page for #{problem_name}"
end