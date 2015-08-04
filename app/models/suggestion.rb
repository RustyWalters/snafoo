class Suggestion < ActiveRecord::Base
  attr_accessor :monthly_suggestion
  attr_accessor :service_error
  validates :name, :location, presence: true
  validate :check_for_duplicates
  validate :monthly_suggestion_made

  def check_for_duplicates
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
      if monthly_suggestion
        logger.debug "monthly_suggestion_made => #{monthly_suggestion}"
        errors[:base] << "Monthly suggestion already made."
      end   
  end
  
end
