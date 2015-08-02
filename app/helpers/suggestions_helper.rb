module SuggestionsHelper
      
  def retrieve_snack_list
    response = RestClient.get 'https://api-snacks.nerderylabs.com/v1/snacks?ApiKey=e1daaff1-786d-431c-9d59-c00054451baf'
    parsed = JSON.parse(response) 
  end

  def string_to_hash (hash_as_string)
    hash = {}
    hash_as_string.split(',').each do |pair|
      key,value = pair.split(/:/)
      hash[key] = value
    end
  end
  
end
