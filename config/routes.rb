Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'signup', to: 'users#create'
      post 'users', to: 'users#create'
      post 'login', to: 'users#login'
      delete 'logout', to: 'users#logout'
      get 'users/me', to: 'users#me'
      put 'users/:id/admin', to: 'users#update_admin'
      get 'predictions', to: 'predictions#index'
      post 'predictions', to: 'predictions#create'
      post 'predictions/:id/vote', to: 'predictions#vote'
      get  'predictions/votes', to: 'predictions#votes'
      put 'predictions/:id/status', to: 'predictions#update_status'
      get 'predictions/:id', to: 'predictions#show'
      get 'leaderboards', to: 'leaderboards#index'
    end
  end
end