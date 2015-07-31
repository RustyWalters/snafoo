require 'rest-client'

class SuggestionsController < ApplicationController


  def index
    @suggestions = ["Suggestion 1", "Suggestion 2", "Suggestion 3"]
  end

  def new
    logger.debug "inside new action"
    response = RestClient.get 'https://api-snacks.nerderylabs.com/v1/snacks?ApiKey=e1daaff1-786d-431c-9d59-c00054451baf'
    @parsed = JSON.parse(response)
   
    optional_snacks = @parsed.select { |snack| snack['optional'] }

    
    @snacks = optional_snacks.map() do |snack|
      result = Array.new
      result << snack['name']  
      result << snack['id']
    end
  end

  def create
    new_suggestion_name = params[:sug_name]
    new_purchase_location = params[:pur_location]
    url = 'https://api-snacks.nerderylabs.com/v1/snacks?ApiKey=e1daaff1-786d-431c-9d59-c00054451baf'
    response = RestClient.post url, {name: new_suggestion_name, location: new_purchase_location}.to_json, content_type: :json
    redirect_to suggestions_new_url

  end

end
