Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  #
  get "flip_items/:id", to: "flip_items#show", as: :flip_item
  get "flip_items", to: "flip_items#index", as: :flip_items
  get "flip_items/:id/edit", to: "flip_items#edit", as: :edit_flip_item
  get "flip_items/:id/check_for_typos", to: "flip_items#check_for_typos", as: :check_flip_item_typos
  patch "flip_items/:id", to: "flip_items#update"
  post "flip_items", to: "flip_items#create"

  get "chats", to: "chats#index"
  get "chats/:id", to: "chats#show", as: :chat
  post "chats/:chat_id/messages", to: "messages#create", as: :chat_messages
  # resources :flip_items
  # Defines the root path route ("/")
  root "flip_items#index"
end
