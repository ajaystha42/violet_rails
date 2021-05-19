require 'sidekiq/web'
class SubdomainConstraint
  def self.matches?(request)
    # plug in exclusions model here
    subdomains = []
    !subdomains.include?(request.subdomain)
  end
end

Rails.application.routes.draw do

  resources :signup_wizard
  resources :signin_wizard
  constraints SubdomainConstraint do
    devise_for :users, controllers: {
      confirmations: 'users/confirmations',
      #omniauth_callbacks: 'users/omniauth_callbacks',
      registrations: 'users/registrations',
      passwords: 'users/passwords',
      sessions: 'users/sessions',
      unlocks: 'users/unlocks',
      invitations: 'devise/invitations'
    }
    
    resource :mailbox, only: [:show], controller: 'mailbox/mailbox' do
      resources :message_threads, controller: 'mailbox/message_threads' do
        resources :messages
        member do
          post 'send_message'
        end
      end
    end
  end

  resources :users, controller: 'comfy/admin/users', as: :admin_users, except: [:create, :show] do
    collection do 
      post 'invite'
    end
  end

  # system admin panel login
  devise_scope :user do
    get 'sign_in', to: 'users/sessions#new', as: :new_global_admin_session
    post 'users/sign_in', to: 'users/sessions#create'
    delete 'global_login', to: 'users/sessions#destroy'
  end
  # system admin panel authentication (ensure public schema as well)
  get 'admin', to: 'admin/subdomain_requests#index'
  namespace :admin do
    mount Sidekiq::Web => '/sidekiq'
    resources :subdomain_requests, except: [:new, :create] do
      member do
        get 'approve'
        get 'disapprove'
      end
    end
    resources :subdomains
  end
  
  comfy_route :cms_admin, path: "/admin"
  comfy_route :blog, path: "blog"
  comfy_route :blog_admin, path: "admin"
  mount SimpleDiscussion::Engine => "/forum"
  # cms comes last because its a catch all
  comfy_route :cms, path: "/"
  
  root to: 'content#index'
  

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
