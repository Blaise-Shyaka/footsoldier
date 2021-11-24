Rails.application.routes.draw do
  resources :union_pay_banks
  resources :union_pay_merchants
  devise_for :users, :controllers => { registrations: 'users/registrations' }
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  devise_scope :user do
    root :to => 'devise/sessions#new'
  end
  resources :users, only: [:show]
  namespace :admin do
    post "approve_user/approve_user"
    get "approve_user/approve"
  end
end
