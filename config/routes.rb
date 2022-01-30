Rails.application.routes.draw do
  resources :tasks
  root "tasks#index"

  post '/callback', to: 'line_bots#callback', as: :callback
  # resources :line_bot
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
