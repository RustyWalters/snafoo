require 'rest-client'
require 'date'

class SuggestionsController < ApplicationController

  include SuggestionsHelper
  SELECT_SNACK_ID = '999999999'

  def index
    @suggestions = Suggestion.all
  end

  def new
    @suggestion = Suggestion.new
    logger.debug "inside new action"
    build_snack_list
    
  end

  def build_snack_list
    @parsed = retrieve_snack_list
    optional_snacks = @parsed.select { |snack| snack['optional'] }  
    @snacks = optional_snacks.map() do |snack|
      result = Array.new
      result << snack['name']  
      result << snack['id']
    end

    #add a default 
    @snacks << ['Select Snack', SELECT_SNACK_ID]    
  end

  def create
    if drop_down_selection? 
      process_list_suggestion
    else
      process_new_suggestion
    end
  end

  def process_list_suggestion
    logger.debug "inside process_list_suggestion"
    selected_id = params[:dd_suggestion]
    logger.debug "selected_id => #{selected_id}"
    @parsed = retrieve_snack_list
    selected_snack = @parsed.select do |snack| 
      logger.debug "parsed snack id => #{snack['id']}"
      if snack['id'] == selected_id.to_i
        #, :lastPurchasedDate => snack['lastPurchaseDate']
        suggestion = Suggestion.new(:snackRefId => snack['id'], :name => snack['name'], :location => snack['purchaseLocations'])
        if suggestion.valid?
          purchase_date = snack['lastPurchaseDate']
          if purchase_date
            suggestion.lastPurchasedDate = purchase_date
          end
          month_now = Date.today.mon
          suggestion.suggestedMonth = month_now
          logger.debug "selected snack from list: #{suggestion}"      
          suggestion.save
          redirect_to new_suggestion_url
        else
          render :new
        end
      end
    end 
  end

  def process_new_suggestion
    logger.debug "inside process_new_suggestion"
    suggestion_params = params.require(:suggestion).permit(:name, :location, :dd_suggestion)
    @suggestion = Suggestion.new(suggestion_params)
    month_now = Date.today.mon
    @suggestion.suggestedMonth = month_now
 
    @suggestion.check_for_duplicates

    if @suggestion.valid?
      url = 'https://api-snacks.nerderylabs.com/v1/snacks?ApiKey=e1daaff1-786d-431c-9d59-c00054451baf'
      response = RestClient.post url, {name: @suggestion.name, location: @suggestion.location}.to_json, content_type: :json
      response_as_hash = JSON.parse(response)
      logger.debug "web service response as hash: #{response_as_hash}"
      new_id = response_as_hash['id']
      logger.debug "web service response: #{response}"
      logger.debug "new snack id => #{new_id}"
      @suggestion.snackRefId = new_id
      @suggestion.save
      redirect_to new_suggestion_url
    else
      build_snack_list
      render :new
    end
  end

  def drop_down_selection?
    params[:dd_suggestion] != SELECT_SNACK_ID
  end

end
