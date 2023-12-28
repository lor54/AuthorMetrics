Rails.application.routes.draw do

  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registration: 'users/registrations',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end

  resources :users
  get '/author_followed', to: 'users#author_followed', as: 'author_followed'

  resources :follows, only: [:destroy]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"
  resources :conferences, only: [:index, :show]
  get "/authors", to: "authors#index"
  resources :authors, only: [:show] do
    resources :follows, path: 'author_follows/:name' , only: [:create]
  end
  get "/authors/:id/:tab", to: "authors#show"
  get "/publications/:key", to: "publications#index"

  get '/faq', to: 'faq#index'
  get '/faq/:file_name', to: 'faq#show', as: :show_faq
end
