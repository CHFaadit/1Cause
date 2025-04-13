vclass ProposalsController < ApplicationController
    # Action to display the form for creating a new proposal
    def new
      # This action can be used to render the form (if needed)
    end
  
    # Action to handle form submission
    def create
      # Retrieve the cause title from the form submission
      cause_title = params[:cause_title]
  
      # Initialize the session[:proposals] array if it doesn't exist
      session[:proposals] ||= []
  
      # Add the new proposal to the session
      session[:proposals] << { title: cause_title, amount_allocated: 0 }
  
      # Redirect to the charity dashboard
      redirect_to charitydashboard_path
    end
  end