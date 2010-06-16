Spree::Application.routes.draw do |map|

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get :short
  #       post :toggle
  #     end
  #
  #     collection do
  #       get :sold
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get :recent, :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"
   
  match 'login' => 'users_sessions#new'
  match 'logout' => 'users_sessions#destroy'
  match 'signup' => 'users#new'
  root :to => 'products#index'

  resources :products

  #   # Loads all extension routes in the order they are specified.
  #TODO   map.load_extension_routes

  resources :user_session do
    member do
      get :nav_bar
    end
  end
  
  match '/account' => 'users#show'
   
  resources :password_resets

  #   # login mappings should appear before all others
  match '/admin' => 'admin/overview#index', :as => :admin
  
  match '/locale/set' => 'locale#set'

  resources :tax_categories

  resources :countries, :only => :index do
    resources :states
  end

  resources :states, :only => :index
  
  resources :users
  
  
  resources :orders do
    resources :line_items
    resources :creditcards
    resources :creditcard_payments
    member do
      get :address_info
    end 
  end

  resources :orders do
    member do
      get :fatal_shipping
    end
    resources :shipments do
      member do
        get :shipping_method
      end
    end
    resources :checkout do
      member do
        get :register
        put :register
      end
    end
  end

  resources :shipments do
    member do
      get :shipping_method
      put :shipping_method
    end
  end
  
  #   # Search routes
  match 's/:product_group_query' => 'products#index', :as => :simple_search
  match '/pg/:product_group_name' => 'products#index', :as => :pg_search
  match '/t/*id/s/*product_group_query' => 'taxons#show', :as => :taxons_search
  match 't/*id/pg/:product_group_name' => 'taxons#show', :as => :taxons_pg_search

  #   # route globbing for pretty nested taxon and product paths
  match '/t/*id' => 'taxons#show', :as => :nested_taxons
  # 
  #   #moved old taxons route to after nested_taxons so nested_taxons will be default route
  #   #this route maybe removed in the near future (no longer used by core)
  #   map.resources :taxons
  #
  
  
   
  namespace :admin do
    resources :coupons
    resources :zones
    resources :users
    resources :countries do
      resources :states
    end
    resources :states
    resources :tax_categories
    resources :configurations
    resources :products do
      resources :product_properties
      resources :image
      member do
        get :clone
      end 
      resources :variants
      resources :options_types do
        member do
          get :select
          get :remove
        end
        collection do
          get :available
          get :selected
        end
      end
      resources :taxons do
        member do
          post :select
          post :remove
        end
        collection do
          post :available
          get  :selected
        end
      end
    end
    resources :option_types
    resources :properties do
      collection do
        get :filtered
      end
    end
    
    resources :prototypes do
      member do
        post :select
      end

      collection do
        get :available
      end
    end

    resource :mail_settings
    resource :inventory_settings
    resources :google_analytics

    resources :orders do
      resources :adjustments
      resources :line_items
      resource :checkout
      resources :shipments do
        member do
          put :fire
        end
      end
      resources :return_authorizations do
        member do
          put :fire
        end
      end
      resources :payments do
        member do
          put :fire
          put :finalize
        end
      end
    end  

    resource :general_settings

    resources :taxonomies do
      member do
        get :get_children
      end
      
      resources :taxons
    end

    resources :reports, :only => [:index, :show] do
      collection do
        get :sales_total
      end
    end

    resources :shipments
    resources :shipping_methods
    resources :shipping_categories
    resources :shipping_rates
    resources :tax_rates
    resource  :tax_settings
    resources :calculators
    resources :product_groups do
      resources :product_scopes
    end
    
  
    resources :trackers
    resources :payment_methods
  end

  match '/:controller(/:action(/:id(.:format)))'
  
  #   # a catchall route for "static" content
  match '*path' => 'content#show'

end