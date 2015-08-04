require 'rest-client'
require 'date'

class SuggestionsController < ApplicationController

  include SuggestionsHelper
  SELECT_SNACK_ID = '999999999'

  respond_to :js, :json, :html

  rescue_from ActiveRecord::RecordNotFound do
    flash[:notice] = 'The object you tried to access does not exist'
    redirect_to vote_path
  end

  def index
    suggestions = Suggestion.all
    @selected_snacks = suggestions.select do |snack|
      snack['suggestedMonth'] == Date.today.mon
    end
    @mycookie = cookies[:monthly_suggestion]
  end

  def new
    @suggestion = Suggestion.new
    build_snack_list    
  end


  def create
    if drop_down_selection? 
      process_list_suggestion
    else
      process_new_suggestion
    end
  end

  def vote
    logger.debug "inside vote action parameter: #{params[:snackRefId]}"
    ref_id = params[:snackRefId]
    if ref_id
      @suggestion = Suggestion.find_by(:snackRefId => ref_id)
      @suggestion.votes = @suggestion.votes + 1
      logger.debug "#{@suggestion.votes} for snack #{@suggestion.name}"
      result = @suggestion.save
      logger.debug "Any errors: #{result}, there are #{@suggestion.errors.count}"
      @suggestion.errors.full_messages.each do |message| 
        logger.debug message
      end
    end
    #redirect_to suggestions_url
    #redirect_to :back
    if request.xhr?
        render :json => {
          :votes => @suggestion.votes }
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
        @suggestion = Suggestion.new(:snackRefId => snack['id'], :name => snack['name'], :location => snack['purchaseLocations'])
        made_suggestion
        @suggestion.monthly_suggestion_made
   
       if @suggestion.valid?
          purchase_date = snack['lastPurchaseDate']
          if purchase_date
            @suggestion.lastPurchasedDate = purchase_date
          end
          month_now = Date.today.mon
          @suggestion.suggestedMonth = month_now
          @suggestion.votes = 0
          logger.debug "selected snack from list: #{@suggestion}"      
          @suggestion.save
          set_monthly_suggestion_cookie
          redirect_to new_suggestion_url
        else
          build_snack_list
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
    
    made_suggestion
    @suggestion.monthly_suggestion_made


    if @suggestion.valid?
      parsed = retrieve_snack_list
      found_snack = parsed.select do |snack|
        snack['name'].strip.downcase == @suggestion['name'].strip.downcase
      end
      logger.debug "found snack => #{found_snack[0]}"
      found_snack = found_snack[0]
      if found_snack
        #only add it to the service if its not there, 
        #otherwise just save as a suggestion
        @suggestion.snackRefId = found_snack['id']
      else
        # url = 'https://api-snacks.nerderylabs.com/v1/snacks?ApiKey=e1daaff1-786d-431c-9d59-c00054451baf'
        # response = RestClient.post url, {name: @suggestion.name, location: @suggestion.location}.to_json, content_type: :json
        response_as_hash = add_snack
        logger.debug "web service response as hash: #{response_as_hash}"
        new_id = response_as_hash['id']
        logger.debug "new snack id => #{new_id}"
        @suggestion.snackRefId = new_id
      end
      @suggestion.votes = 0
      @suggestion.save
      set_monthly_suggestion_cookie
      redirect_to new_suggestion_url
    else
      build_snack_list
      render :new
    end
  end

  def made_suggestion
      cookie_value = cookies[:monthly_suggestion] 
      logger.debug "made_suggestion cookie_value => #{cookie_value}"
      @suggestion.monthly_suggestion = cookie_value == 'taken'
  end

  def set_monthly_suggestion_cookie
    cookies[:monthly_suggestion] = {
      :value => "taken",
      :expires => 1.month.from_now
    }
  end


  def drop_down_selection?
    params[:dd_suggestion] != SELECT_SNACK_ID
  end

  def build_snack_list
    #get list of snacks from web service
    @parsed = retrieve_snack_list

    #filter out the optional snack from the web service
    optional_snacks = @parsed.select { |snack| snack['optional'] }  
  
    #retrieve suggested snacks from DB
    selected_snacks = Suggestion.all
      
    #key function - filter out the already suggested snacks
    #from the list of optional snacks from the web service
    selected_snacks.each do |sel_snack|
      optional_snacks.reject! do |snack|
        snack['id'] == sel_snack['snackRefId'] &&
        sel_snack['suggestedMonth'] == Date.today.mon
      end
    end

    #prepare final list of of snacks for display
    @snacks = optional_snacks.map() do |snack|
       result = Array.new
       result << snack['name']  
       result << snack['id']
    end
  
    # #add a default so we know if user selected a snack
    #from the list or added a new one
    @snacks << ['Select Snack', SELECT_SNACK_ID]    
  end
end
