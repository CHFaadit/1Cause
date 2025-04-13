require 'nokogiri'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'open-uri'
require 'json'
require 'net/http'
require 'uri'
require 'erb'
require 'dotenv/load'

# --- Backend (Scraping and GPT Interaction) ---

def scrape_news(urls)
  articles = []
  limit = 5
  urls.each do |url|
    break if articles.length >= limit # Stop if 10 articles are found

    begin
      puts "Scraping: #{url}"
      html = URI.open(url)
      doc = Nokogiri::HTML(html)

      doc.css('article').each do |article| # Adjust selector if needed
        break if articles.length >= limit # Stop if 10 articles are found

        title = article.css('h2').text.strip
        link = article.css('a').first['href'] rescue nil
        summary = article.css('p').text.strip

        if title && link
          articles << { title: title, link: link, summary: summary }
        end
      end
    rescue OpenURI::HTTPError => e
      puts "Error scraping #{url}: #{e.message}"
    end
  end
  puts "Articles found: #{articles.inspect}"
  articles
end

def get_problem_data(article_summary)
  api_key = ENV['GOOGLE_SEARCH_API']
  return nil unless api_key

  uri = URI('https://api.openai.com/v1/chat/completions')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path, {
    'Content-Type' => 'application/json',
    'Authorization' => "Bearer #{api_key}"
  })

  prompt = "Extract the name, a short description, and a search query to find an image from this news summary: #{article_summary}. Return only the JSON format in plain raw text without using a codebox with ``` and use double quotes for all values: {name: '', description: '', image_query: ''}"

  request.body = {
    model: 'gpt-4o-mini',
    messages: [{ role: 'user', content: prompt }]
  }.to_json

  response = http.request(request)
  
  if response.is_a?(Net::HTTPSuccess)
    begin
      puts "GPT-4 Content: #{JSON.parse(response.body)['choices'][0]['message']['content']}"
      parsed = JSON.parse(JSON.parse(response.body)['choices'][0]['message']['content'])
      puts "GPT-4 JSON Response: #{parsed.inspect}"
      parsed
    rescue JSON::ParserError
      puts "GPT response parsing error."
      nil
    end
  else
    puts "GPT API error: #{response.code} #{response.message}"
    nil
  end
end

def get_image_url(query)
  api_key = api_key = ENV['OPENAI_API_KEY']
  cse_id = ENV['CSE_ID']
  
  return "https://picsum.photos/200/200" unless api_key && cse_id

  uri = URI("https://www.googleapis.com/customsearch/v1?key=#{api_key}&cx=#{cse_id}&q=#{URI.encode_www_form_component(query)}&searchType=image")
  puts "Fetching image for query: #{query}"

  begin
    response = Net::HTTP.get(uri)
    json = JSON.parse(response)
    image_url = json['items']&.first&.dig('link') || "https://picsum.photos/200/200"
    puts "Image URL: #{image_url}"
    image_url
  rescue StandardError => e
    puts "Error fetching image: #{e.message}"
    "https://picsum.photos/200/200"
  end
end

def process_problems(articles)
  problems = []
  articles.each do |article|
    puts "Processing article: #{article[:summary]}"
    problem_data = get_problem_data(article[:summary])
    sleep 10
    next unless problem_data

    image_url = get_image_url(problem_data['image_query'])

    problems << {
      name: problem_data['name'],
      description: problem_data['description'],
      image_url: image_url,
      link: article[:link]
    }
  end
  puts "Final Problems List: #{problems.inspect}"
  problems
end

# --- Frontend (Sinatra Server) ---

set :port, 4567

get '/' do
  puts "Starting problem extraction pipeline..."
  news_urls = [
    'https://www.humanitariancoalition.ca/current-crises',
    'https://www.aljazeera.com/tag/humanitarian-crises/',
    'https://www.unrefugees.org/emergencies/'
  ]

  articles = scrape_news(news_urls)
  @problems = process_problems(articles)
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
