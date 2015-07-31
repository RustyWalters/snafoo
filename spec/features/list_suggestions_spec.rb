require 'spec_helper'

describe "Viewing the list of suggestions" do
	
	it "shows the suggestions" do
		
		visit suggestions_url

		expect(page).to have_text("Suggestions")
    expect(page).to have_text("Suggestion 1")
    expect(page).to have_text("Suggestion 2")
    expect(page).to have_text("Suggestion 3")
	end

end