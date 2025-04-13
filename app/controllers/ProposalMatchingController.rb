require 'dotenv/load'

class ProposalMatchingController < ApplicationController
    require 'httparty'
    require 'json'
  
    # POST /run_model
    def run_model
      # Hardcoded proposals (These can be fetched from the database if necessary)
      proposals = [
        {
          cause_title: 'Biodiversity and Climate Change',
          funding_needed: 18000,
          corporate_matching: true,
          impact: 'Expanding protected marine areas to safeguard aquatic ecosystems from climate change.',
          milestones: 'Conduct environmental assessments, establish marine sanctuaries, coral restoration.'
        },
        {
          cause_title: 'Biodiversity and Climate Change',
          funding_needed: 25000,
          corporate_matching: false,
          impact: 'Funding scientific research on endangered species and climate change impacts.',
          milestones: 'Track species populations, publish annual reports, raise awareness.'
        },
        {
          cause_title: 'Biodiversity and Climate Change',
          funding_needed: 12000,
          corporate_matching: true,
          impact: 'Reforestation and wetland restoration to enhance biodiversity and mitigate climate effects.',
          milestones: 'Plant native species, rehabilitate wetlands, engage local communities.'
        },
        {
          cause_title: 'Biodiversity and Climate Change',
          funding_needed: 15000,
          corporate_matching: false,
          impact: 'Building grassroots support for biodiversity through education and sustainable practices.',
          milestones: 'Conduct workshops, collaborate with schools, raise awareness in local communities.'
        },
        {
          cause_title: 'Biodiversity and Climate Change',
          funding_needed: 11000,
          corporate_matching: true,
          impact: 'Integrating biodiversity-friendly practices in agriculture to protect wildlife habitats.',
          milestones: 'Train farmers, develop certification programs, expand sustainable farming.'
        }
      ]
  
      # Construct the OpenAI prompt
      prompt = "You are an AI evaluator for charitable fund allocation. Below are the details of proposals from different charities focused on biodiversity and climate change:\n"
      proposals.each_with_index do |proposal, index|
        prompt += "#{index + 1}. Title: #{proposal[:cause_title]}\n"
        prompt += "   Funding Needed: $#{proposal[:funding_needed]}\n"
        prompt += "   Corporate Matching: #{proposal[:corporate_matching] ? 'Yes' : 'No'}\n"
        prompt += "   Impact: #{proposal[:impact]}\n"
        prompt += "   Milestones: #{proposal[:milestones]}\n\n"
      end
      prompt += "The total available fund is $50000.\n"
      prompt += "Based on the funding needs, corporate matching opportunities, impact, and milestones, allocate the available funds between these proposals. Provide the amount allocated to each proposal and explain the rationale for the allocation."
  
      # Call OpenAI API for evaluation
      response = HTTParty.post(
        "https://api.openai.com/v1/completions",
        body: {
          model: "gpt-4o-mini", # Update with the model you are using
          prompt: prompt,
          max_tokens: 2000,
          temperature: 0.7,
          n: 1,
          stop: ["\n"]
        }.to_json,
        headers: {
  'Authorization' => "Bearer #{ENV['OPENAI_API_KEY']}",
  'Content-Type' => 'application/json'
}
        }
      )
  
      ai_response = JSON.parse(response.body)
      allocation_result = ai_response['choices'][0]['text'].strip
  
      # Parse and return the allocations and rationale
      allocations, rationale = parse_allocation_result(allocation_result)
  
      # Return the allocation result and rationale to the frontend
      render json: { allocations: allocations, rationale: rationale }
    end
  
    private
  
    # Parse the OpenAI allocation result and extract the values
    def parse_allocation_result(result)
      allocations = []
      rationale = ''
      result.split("\n").each do |line|
        if line.include?("received")
          allocation = line.match(/(\$[0-9,]+)/)
          allocations << allocation[0] if allocation
        elsif line.include?("allocation")
          rationale += line + "\n"
        end
      end
      return allocations, rationale
    end
  end
  