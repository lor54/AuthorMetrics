Rails.application.routes.draw do
  get 'users/show'
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registration: 'users/registrations',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end

  resources :users do
    resources :follows, only: [:create]
  end

  resources :follows, only: [:destroy]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"
  resources :conferences, only: [:index, :show] do
    resources :editions, only: [:show]
  end
  get "/authors", to: "authors#index"
  get "/authors/:id", to: "authors#show"
  get "/authors/:id/:tab", to: "authors#show"
  get "/publications/:key", to: "publications#index"

end
