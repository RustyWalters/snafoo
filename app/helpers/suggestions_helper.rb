module SuggestionsHelper
      
  def retrieve_snack_list
    response = RestClient.get 'https://api-snacks.nerderylabs.com/v1/snacks?ApiKey=e1daaff1-786d-431c-9d59-c00054451baf'
    parsed = JSON.parse(response) 
  end
end
