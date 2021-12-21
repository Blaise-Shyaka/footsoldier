Rails.application.routes.draw do
  resources :chef_wumujyis
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

  namespace :union_pay do
    get "reports/merchants"
    get "reports/banks"
    get "reports/merchants_analysis"
    get "reports/banks_analysis"
  end

  namespace :engen do
    get "reports/sales_per_day"
    get "reports/sales_per_promoter"
    get "reports/download_csv", format: 'csv'
  end
end
