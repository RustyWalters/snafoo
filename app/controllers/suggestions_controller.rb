require 'rest-client'
require 'date'

class SuggestionsController < ApplicationController

  include SuggestionsHelper
  SELECT_SNACK_ID = '999999999' #used to know if default selection has changed

  respond_to :js, :json, :html

  rescue_from ActiveRecord::RecordNotFound do
    flash[:notice] = 'The object you tried to access does not exist'
    redirect_to vote_path
  end

  def index
    #retrieve saved selections and select only the ones suggestion for current month
    suggestions = Suggestion.all
    @selected_snacks = suggestions.select do |snack|
      snack['suggestedMonth'] == Date.today.mon
    end

    #retrieve all snacks from web service, and filter to just the ones always purchased
    snack_list = retrieve_snack_list
    @purchased_snacks = snack_list.reject { |snack| snack['optional'] }  
    logger.debug "Number of purchased_snacks => #{@purchased_snacks.size}"
    
    #retrieve voting cookie value so we can display it  
    get_voting_cookie
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
    end

    #set the voting cookie, if nil, we know we've exceeded number of votes
    set_voting_cookie
    if @voting_count.nil?
      @voting_count = 0
    else
      #if number of votes not exceeded, allow vote, and subtract one from the count
      @suggestion.votes = @suggestion.votes + 1
      logger.debug "#{@suggestion.votes} for snack #{@suggestion.name}"
      result = @suggestion.save
      logger.debug "Any errors: #{result}, there are #{@suggestion.errors.count}"
      @suggestion.errors.full_messages.each do |message| 
        logger.debug message
      end
    end     

    #voting is using ajax call, so we need to render the response passing
    #the updated suggestion vote count and total number of votes taken by user
    if request.xhr?
      render :json => {
             :votes => @suggestion.votes,
             :voting_count => @voting_count }
    end
  end

  def process_list_suggestion
    logger.debug "inside process_list_suggestion"
    #retrieve the selected snack id from the dropdown list selection
    selected_id = params[:dd_suggestion]
    logger.debug "selected_id => #{selected_id}"
    
    #retrieve snack list from web service so we can use the values from
    #it for saving the suggestion based on the selected snack
    @parsed = retrieve_snack_list

    selected_snack = @parsed.select do |snack| 
      logger.debug "parsed snack id => #{snack['id']}"
      #we found the selected snack from the web service list
      if snack['id'] == selected_id.to_i
        #create a suggestion based on the values from the web service
        @suggestion = Suggestion.new(:snackRefId => snack['id'], :name => snack['name'], :location => snack['purchaseLocations'])
        #call method to record the user has made a selection
        made_suggestion
        @suggestion.monthly_suggestion_made
   
       #check to see if the suggestion we are about to save is valid
       if @suggestion.valid?
          #if the web service snack has purchase date, add it to the suggestion
          purchase_date = snack['lastPurchaseDate']
          if purchase_date
            @suggestion.lastPurchasedDate = purchase_date
          end
          #set the suggestion month to today's current month
          month_now = Date.today.mon
          @suggestion.suggestedMonth = month_now
          @suggestion.votes = 0
          logger.debug "selected snack from list: #{@suggestion}"      
          @suggestion.save
          set_monthly_suggestion_cookie
          redirect_to new_suggestion_url
        else #if the suggestion isn't valid, rebuild snack list and redisplay the page
          build_snack_list
          render :new
        end
      end
    end 
  end

  def process_new_suggestion
    logger.debug "inside process_new_suggestion"
    #create new suggestion based on parameters coming from form
    suggestion_params = params.require(:suggestion).permit(:name, :location, :dd_suggestion)
    @suggestion = Suggestion.new(suggestion_params)
    month_now = Date.today.mon
    @suggestion.suggestedMonth = month_now
    @suggestion.votes = 0
 
    #this will check for duplicates
    @suggestion.check_for_duplicates
    
    #record a suggestion was made by creating a new one
    made_suggestion
    @suggestion.monthly_suggestion_made


    if @suggestion.valid?
      #retrieve snack list from service to make sure the newly entered snack
      #isn't a duplicate on the service side before adding it
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
        #call service to add the snack
        response_as_hash = add_snack
        logger.debug "web service response as hash: #{response_as_hash}"
        new_id = response_as_hash['id']
        #retrieve the id from the new snack added to the web service
        #so we can save the id as snackRefId in our suggestion table
        logger.debug "new snack id => #{new_id}"
        @suggestion.snackRefId = new_id
      end
      @suggestion.save
      set_monthly_suggestion_cookie
      redirect_to new_suggestion_url
    else
      build_snack_list
      render :new
    end
  end

  def made_suggestion
    #setting flag to determine if monthly suggestion has been taken or not
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

  def get_voting_cookie
    #retrieve voting cookie, if it doesn't exist, create a cookie with 3 vote available
    #for the given month
    @voting_count = cookies[:voting_count]
    if @voting_count.nil?
      cookies[:voting_count] = { :value => 3, :expires => 1.month.from_now }
      @voting_count = cookies[:voting_count]
    end  
  end

  def set_voting_cookie
    @voting_count = cookies[:voting_count].to_i

    #if we have votes left, go ahead and let the vote continue
    #otherwise stop the vote from occurring.
    if @voting_count && @voting_count > 0
      cookies[:voting_count] = @voting_count - 1
      @voting_count = cookies[:voting_count]
    elsif @voting_count && @voting_count == 0
      logger.debug("voting count is at #{@voting_count}")
      @voting_count = nil     
    end
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
    @snacks.unshift ['Select Snack', SELECT_SNACK_ID]    
  end
end
