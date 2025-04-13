require 'nokogiri'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'open-uri'
require 'json'
require 'net/http'
require 'uri'
require 'erb'
require 'aws-sdk-dynamodb'
require 'securerandom'
require 'dotenv/load'

# --- Backend (GPT Interaction - Now includes scraping and saving to DynamoDB) ---

def get_problem_data
  api_key = ENV['OPENAI_API_KEY']
  uri = URI('https://api.openai.com/v1/chat/completions')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path, {
    'Content-Type' => 'application/json',
    'Authorization' => "Bearer #{api_key}"
  })

  urls_to_scrape = [
    'https://www.greenpeace.org/canada/en/explore/',
    'https://unglobalcompact.org/what-is-gc/our-work/environment',
    'https://www.unrefugees.org/emergencies/',
    'https://www.thenewhumanitarian.org/conflict',
    'https://www.aljazeera.com/tag/humanitarian-crises/'
  ]

  prompt = "Scrape these websites for a list of relevant issues that a user can donate to, stop running after finding 28 causes, and take one cause from each website and then move to the next website and repeat after you have taken a cause from each website: #{urls_to_scrape.join(' ')}. Extract the name, a short description, link for the article, a google search query to find an image for each cause and a type that is either {environmental, health, humanitarian}. Return only the JSON format in plain raw text without using a codebox with ``` and use double quotes for all values in a JSON array: [{\"name\": \"\", \"description\": \"\", \"link\": \"\", \"image_query\": \"\", \"type\": \"\"}, {\"name\": \"\", \"description\": \"\", \"link\": \"\", \"image_query\": \"\", \"type\": \"\"}, ...]"

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

      dynamodb = Aws::DynamoDB::Client.new(
        region: ENV['AWS_REGION'],
        credentials: Aws::Credentials.new(
          ENV['AWS_ACCESS_KEY_ID'],
          ENV['AWS_SECRET_ACCESS_KEY']
        )
      )
      
      

      saved_problems = 0
      parsed_problems_data.each do |problem|
        break if saved_problems >= 28
        item = {
          id: SecureRandom.uuid,
          name: problem['name'],
          description: problem['description'],
          link: problem['link'],
          image_query: problem['image_query'],
          donated: 0,
          type: problem['type']
        }

        begin
          dynamodb.put_item(table_name: 'Issues', item: item)
          puts "Saved issue '#{problem['name']}' to DynamoDB."
          saved_problems += 1
        rescue Aws::DynamoDB::Errors::ServiceError => e
          puts "Error saving to DynamoDB: #{e.message}"
        end
      end

      return { status: 'success', message: 'Issues updated successfully.' } # Explicit return here
    rescue JSON::ParserError => e
      puts "GPT response parsing error: #{e.message}"
      puts "Problematic GPT Content: #{gpt_content}"
      return { status: 'error', message: "GPT response parsing error: #{e.message}" }
    end
  else
    puts "GPT API error: #{response.code} #{response.message}"
    return { status: 'error', message: "GPT API error: #{response.code} #{response.message}" }
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
      link: problem['link'], # Since we removed scraping individual article links
      donation: 0,
      type: problem['type']
    }
  end
  puts "Final Problems List: #{problems.inspect}"
  problems
end

# --- Frontend (Sinatra Server) ---

set :port, 4567

get '/' do
  puts "Fetching issues from DynamoDB..."
  dynamodb = Aws::DynamoDB::Client.new(
    region: ENV['AWS_REGION'],
    credentials: Aws::Credentials.new(
      ENV['AWS_ACCESS_KEY_ID'],
      ENV['AWS_SECRET_ACCESS_KEY']
    )
  )
  

  begin
    response = dynamodb.scan(table_name: 'Issues')
    @problems = response.items.map do |item|
      {
        name: item['name'],
        description: item['description'],
        image_url: get_image_url(item['image_query']), # Fetch image URL here
        link: item['link'],
        donated: 0,
        type: item['type']
      }
    end
    puts "Retrieved problems from DynamoDB: #{@problems.inspect}"
  rescue Aws::DynamoDB::Errors::ServiceError => e
    puts "Error fetching from DynamoDB: #{e.message}"
    @problems = []
  end

  erb :index
end

get '/update_issues' do
    result = get_problem_data
    if result[:status] == 'success'
      result[:message]
    else
      "Error updating issues: #{result[:message]}"
    end
end

post '/donate/:problem_name' do
  problem_name = params[:problem_name]
  "Donation processed for #{problem_name}"
end

get '/claim/:problem_name' do
  problem_name = params[:problem_name]
  "Claim page for #{problem_name}"
end