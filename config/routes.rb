Rails.application.routes.draw do
  root "suggestions#index"
  get "suggestions/vote" => "suggestions#vote", as: "vote"
  resources :suggestions
end
