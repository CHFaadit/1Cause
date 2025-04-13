Rails.application.routes.draw do
  root 'pages#home'  # Home page

  get '/login', to: 'pages#login'  # Route for login page
  get '/donordashboard', to: 'pages#donordashboard'
  get 'charitydashboard', to: 'pages#charitydashboard'

  post 'submit-proposal', to: 'proposals#create'
  get 'charityproposal', to: 'pages#charityproposal'
  post 'submit_proposal', to: 'proposals#create'

  get '/payments/:problem_name', to: 'pages#payment', as: :payments

  get '/rationale', to: 'pages#rationale', as: 'rationale'
  get '/problems', to: 'problems#index', as: :problems
  post '/problems/donate/:problem_name', to: 'problems#donate', as: :donate_problems
  get '/problems/claim/:problem_name', to: 'problems#claim', as: :claim_problems
  get '/update_issues', to: 'problems#update_issues'


end
