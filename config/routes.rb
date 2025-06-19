Rails.application.routes.draw do
  root "home#index"
  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :users, only: [:index] do
    collection do
      get :search
    end
  end
  
  # Simple test endpoints for VulnChaser
  get '/test/sql', to: 'simple_test#sql_test'
  post '/test/auth', to: 'simple_test#auth_test'
  get '/test/health', to: 'simple_test#health'
end
