Rails.application.routes.draw do
  get 'users/show'
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registration: 'users/registrations'
  }

  devise_scope :user do  
    get '/users/sign_out' => 'devise/sessions#destroy'     
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"
  get '/conferences', to: "conferences#index"
  get '/conferences/:id', to: "conferences#show"
  get "/authors", to: "authors#index"
  get "/authors/:id", to: "authors#show"
  get "/authors/:id/:tab", to: "authors#show"
  get "/publications/:key", to: "publications#index"

end
