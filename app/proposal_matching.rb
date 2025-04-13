require 'dotenv/load'
require 'httparty'
require 'json'

# Get OpenAI API key from .env
OPENAI_API_KEY = ENV['OPENAI_API_KEY']

# Predefined proposals (5 of them) for the demo
PREVIOUS_PROPOSALS = [
  {
    'cause_title' => 'Biodiversity and Climate Change',
    'funding_needed' => 18000,
    'corporate_matching' => true,
    'impact' => 'This initiative aims to establish and expand protected marine areas to safeguard vulnerable aquatic ecosystems from the dual threats of climate change and overfishing. Our approach integrates science-based marine conservation efforts with eco-friendly tourism to provide sustainable income for local communities while preserving biodiversity. We will work with governments, local businesses, and NGOs to create marine sanctuaries and establish coral restoration programs to combat ocean acidification and loss of marine biodiversity.',
    'milestones' => 'Conduct a comprehensive environmental assessment of key marine ecosystems.\nCollaborate with local governments to designate protected marine areas.\nLaunch a coral restoration project in partnership with environmental NGOs.\nEstablish eco-tourism initiatives that will generate income while promoting conservation.\nCreate educational campaigns for local communities about sustainable fishing practices and marine conservation.'
  },
  {
    'cause_title' => 'Biodiversity and Climate Change',
    'funding_needed' => 25000,
    'corporate_matching' => false,
    'impact' => 'Our focus is on funding cutting-edge scientific research on endangered species, biodiversity loss, and the effects of climate change on ecosystems. We aim to support researchers working in remote ecosystems, track species populations, and identify climate change-induced threats to biodiversity. This research will provide the scientific foundation necessary to inform global conservation policies and help implement effective biodiversity preservation strategies. We will also publish findings and engage the public through outreach programs to raise awareness about the urgency of biodiversity conservation.',
    'milestones' => 'Fund 10+ research projects focused on biodiversity monitoring and species protection in vulnerable regions.\nCollaborate with universities and research institutes to analyze the impacts of climate change on biodiversity.\nTrack the populations of endangered species in key ecosystems.\nPublish annual biodiversity reports to disseminate findings to policymakers and the general public.\nEstablish outreach campaigns to engage local communities and raise awareness on the importance of biodiversity conservation.'
  },
  {
    'cause_title' => 'Biodiversity and Climate Change',
    'funding_needed' => 12000,
    'corporate_matching' => true,
    'impact' => 'We aim to restore vital ecosystems through reforestation and wetland rehabilitation. These habitats play a critical role in mitigating climate change and providing homes for countless species. Our project will focus on large-scale tree planting initiatives, restoring wetlands to their natural state, and enhancing biodiversity within degraded ecosystems. The initiative will engage local communities and empower them to take ownership of the restoration process, creating long-term, sustainable environmental benefits while also fostering community resilience to climate change.',
    'milestones' => 'Partner with local communities to identify and restore deforested areas and wetlands.\nBegin planting native tree species and restoring wetland ecosystems.\nMonitor biodiversity improvements and soil health post-restoration.\nCreate educational programs for local residents on the importance of ecosystem restoration and the benefits of maintaining biodiversity.\nDevelop a sustainable funding model by collaborating with corporate partners to fund ongoing restoration efforts.'
  },
  {
    'cause_title' => 'Biodiversity and Climate Change',
    'funding_needed' => 15000,
    'corporate_matching' => false,
    'impact' => 'This initiative focuses on building grassroots support for biodiversity conservation through education, awareness, and capacity building in local communities. By providing training on sustainable land use, waste management, and species protection, we empower individuals and local governments to take proactive steps to preserve biodiversity. We will develop educational resources, workshops, and community projects that address local biodiversity threats while creating a sense of ownership and responsibility for the natural environment.',
    'milestones' => 'Develop a series of educational workshops on biodiversity conservation and sustainable practices for local communities.\nPartner with schools to integrate biodiversity education into the curriculum.\nOrganize community-led projects to protect local habitats and species.\nRaise awareness about the importance of biodiversity conservation through media campaigns and local outreach.\nCollaborate with local governments to develop long-term biodiversity protection plans.'
  },
  {
    'cause_title' => 'Biodiversity and Climate Change',
    'funding_needed' => 11000,
    'corporate_matching' => true,
    'impact' => 'Our approach seeks to integrate biodiversity-friendly practices into agricultural systems by working directly with farmers to reduce the environmental impact of farming. We aim to promote sustainable farming methods that protect wildlife habitats, reduce pesticide use, and improve soil health. By offering training, resources, and certification for sustainable agricultural practices, we can ensure that agriculture remains a viable industry while contributing to the protection of biodiversity. This project also seeks to create partnerships with agricultural organizations to expand the reach of sustainable practices across regions.',
    'milestones' => 'Conduct training programs for farmers on sustainable farming practices, focusing on biodiversity-friendly techniques.\nDevelop a certification program for farmers who adopt biodiversity-conscious practices.\nPartner with agricultural organizations to expand sustainable farming practices across rural regions.\nLaunch a national campaign to promote the benefits of sustainable agriculture for biodiversity conservation.\nMonitor the impact of these practices on local biodiversity and ecosystem health.'
  }
]

class ProposalMatching
  def self.allocate_funds_to_proposals(selected_cause)
    # Set the donated amount dynamically based on the selected cause
    donated_amount = 50000  # Fixed amount for demo, can be adjusted dynamically as needed

    # Combine the selected cause with the predefined proposals
    proposals = PREVIOUS_PROPOSALS.map do |proposal|
      if proposal['cause_title'] == selected_cause['cause_title']
        proposal['funding_needed'] = donated_amount
      end
      proposal
    end

    # Construct the prompt for OpenAI
    prompt = "You are an AI evaluator for charitable fund allocation. Below are the details of proposals from different charities focused on biodiversity and climate change:\n"

    proposals.each_with_index do |proposal, index|
      prompt += "#{index + 1}. Title: #{proposal['cause_title']}\n"
      prompt += "   Funding Needed: $#{proposal['funding_needed']}\n"
      prompt += "   Corporate Matching: #{proposal['corporate_matching'] ? 'Yes' : 'No'}\n"
      prompt += "   Impact: #{proposal['impact']}\n"
      prompt += "   Milestones: #{proposal['milestones']}\n\n"
    end

    prompt += "The total available fund is $#{donated_amount}.\n"
    prompt += "Based on the funding needs, corporate matching opportunities, impact, and milestones, allocate the available funds between these proposals. Provide the amount allocated to each proposal and explain the rationale for the allocation."

    # Call OpenAI API for evaluation
    response = HTTParty.post(
      "https://api.openai.com/v1/completions",
      body: {
        model: "gpt-4o-mini",
        prompt: prompt,
        max_tokens: 1000,
        temperature: 0.7,
        n: 1,
        stop: ["\n"]
      }.to_json,
      headers: {
        'Authorization' => "Bearer #{OPENAI_API_KEY}",
        'Content-Type' => 'application/json'
      }
    )

    # Parse the AI response
    ai_response = JSON.parse(response.body)
    allocation_result = ai_response['choices'][0]['text'].strip

    # Return the allocation result
    allocation_result
  end
end
