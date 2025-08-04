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
  
  # Admin panel endpoints
  scope '/admin' do
    get '/users', to: 'admin#find_users'
    post '/auth', to: 'admin#authenticate'
    get '/files', to: 'admin#download_asset'
    get '/settings', to: 'admin#get_settings'
    post '/feedback', to: 'admin#add_feedback'
    post '/register', to: 'admin#register_user'
    post '/import', to: 'admin#import_data'
    post '/config', to: 'admin#load_config'
    post '/documents', to: 'admin#store_document'
    post '/analytics', to: 'admin#track_request'
    post '/sessions', to: 'admin#start_session'
    post '/tokens', to: 'admin#verify_token'
    
    # Legacy processing endpoints using vulnerable gems
    post '/xml-legacy', to: 'admin#process_legacy_xml'
    post '/json-complex', to: 'admin#process_complex_json'
    post '/markdown', to: 'admin#render_markdown'
    post '/convert', to: 'admin#convert_document'
    post '/json-legacy', to: 'admin#parse_legacy_json'
  end
  
  # Advanced system endpoints
  scope '/system' do
    post '/verify', to: 'system#verify_signature'
    post '/workflow', to: 'system#process_workflow'
    post '/binary', to: 'system#analyze_binary_data'
    post '/calculate', to: 'system#calculate_metrics'
    post '/normalize', to: 'system#normalize_identifier'
    post '/deserialize', to: 'system#process_serialized_object'
  end
  
  # Payment processing endpoints  
  scope '/payment' do
    post '/process', to: 'payment#process_transaction'
    post '/refund', to: 'payment#process_refund'
    post '/discount', to: 'payment#validate_discount'
    post '/pricing', to: 'payment#calculate_price'
  end
  
  # Image processing endpoints with library vulnerabilities
  scope '/image' do
    post '/mini-magick', to: 'image#process_with_mini_magick'
    post '/image-processing', to: 'image#process_with_image_processing'
    post '/batch', to: 'image#batch_process_images'
    get '/info', to: 'image#imagemagick_info'
  end
end
