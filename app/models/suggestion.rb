class Suggestion < ActiveRecord::Base
  attr_accessor :monthly_suggestion
  attr_accessor :service_error
  validates :name, :location, presence: true
  validate :check_for_duplicates
  validate :monthly_suggestion_made

  def check_for_duplicates
    #needed to confirm all 3 attributes are the same before considering a duplicate
    #the number of votes needed to be considered, otherwise voting would fail.
    current_suggestions = Suggestion.all
    current_suggestions.each do |sug|
      if sug.name.strip.downcase == name.strip.downcase &&
         sug.suggestedMonth == suggestedMonth &&
         sug.votes == votes
        errors[:base] << "Duplicate suggestions are not allowed."
        break        
      end
    end   
  end

  def monthly_suggestion_made
    #used for displaying an error if the user has already submitted a suggestion
    #for the month
      if monthly_suggestion
        logger.debug "monthly_suggestion_made => #{monthly_suggestion}"
        errors[:base] << "Monthly suggestion already made."
      end   
  end
  
end
