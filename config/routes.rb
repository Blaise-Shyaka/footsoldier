Rails.application.routes.draw do
  resources :bk_arena_pre_registrations
  root :to => "home#home"
  get 'home', to: 'home#home'
  resources :chef_wumujyis
  resources :union_pay_banks
  resources :union_pay_merchants
  devise_for :users, :controllers => { registrations: 'users/registrations', sessions: 'users/sessions' }
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :users, only: [:show]
  namespace :admin do
    post "approve_user/approve_user"
    get "approve_user/approve"
    get "promoter_performance/union_pay"
  end

  namespace :union_pay do
    get "reports/merchants"
    get "reports/banks"
    get "reports/merchants_analysis"
    get "reports/banks_analysis"
    get "reports/download_merchants_csv"
    get "reports/download_atms_csv"
  end

  namespace :engen do
    get "reports/sales_per_day"
    get "reports/sales_per_promoter"
    get "reports/download_csv", format: 'csv'
  end

  namespace :bk_arena do
    get "reports/general_report"
    get "issue_card/search_client"
    get "issue_card/search"
    get "issue_card/:id/edit" => "issue_card#edit"
  end
end
