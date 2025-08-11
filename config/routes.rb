Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'signup', to: 'users#create'
      post 'login', to: 'users#login'
      delete 'logout', to: 'users#logout'
      get 'users/me', to: 'users#me'
      post :push_token, action: :update_push_token
      put 'users/:id/admin', to: 'users#update_admin'
      get 'predictions', to: 'predictions#index'
      post 'predictions', to: 'predictions#create'
      post 'predictions/:id/vote', to: 'predictions#vote'
      get  'predictions/votes', to: 'predictions#votes'
      get 'points_history', to: 'users#points_history'
      put 'predictions/:id/status', to: 'predictions#update_status'
      put  'predictions/:id/approve', to: 'predictions#approve'
      put  'predictions/:id/reject', to: 'predictions#reject'
      delete 'predictions/:id', to: 'predictions#destroy'
      get 'predictions/:id', to: 'predictions#show'
      get 'leaderboards', to: 'leaderboards#index'
      resources :activities, only: [:index]
      resources :rewards, only: [:index, :create] do
        member do
          post 'redeem'
        end
      end
    end
  end
end