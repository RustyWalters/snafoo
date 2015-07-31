Rails.application.routes.draw do

  get "suggestions" => "suggestions#index"
  get "suggestions/new" => "suggestions#new"
  post "suggestions/create" => "suggestions#create"
end
