Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  #
  get "flip_items/:id", to: "flip_item#show", as: :flip_item
  get "flip_items", to: "flip_item#index", as: :flip_items
  get "flip_items/:id/edit", to: "flip_item#edit", as: :edit_flip_item
  patch "flip_items/:id", to: "flip_item#update"
  # resources :flip_items
  # Defines the root path route ("/")
  root "flip_item#index"
end
