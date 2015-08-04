module SuggestionsHelper
   SNACKS_URL =  'https://api-snacks.nerderylabs.com/v1/snacks?ApiKey=e1daaff1-786d-431c-9d59-c00054451baf'

  def retrieve_snack_list
    response = RestClient.get SNACKS_URL
    logger.debug "web service response code => #{response.code}"
    if response.code != 200
      flash[:notice] = "Error: #{response.code} while communicating with services, please try again later."
    end
    parsed = JSON.parse(response) 
  end

  def add_snack
    response = RestClient.post SNACKS_URL, {name: @suggestion.name, location: @suggestion.location}.to_json, content_type: :json
    logger.debug "web service response code => #{response.code}"
    if response.code != 200
      flash[:notice] = "Error: #{response.code} while communicating with services, please try again later."
    end
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
