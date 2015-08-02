class Suggestion < ActiveRecord::Base
  validates :name, :location, presence: true
  validate :check_for_duplicates

  def check_for_duplicates
    current_suggestions = Suggestion.all
    current_suggestions.each do |sug|
      if sug.name.strip.downcase == name.strip.downcase
        errors.add(:name, "Duplicate suggestions are not allowed.") 
        break        
      end
    end   
  end
  
end
