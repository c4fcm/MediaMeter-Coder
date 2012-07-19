UsWorldCoverage::Application.routes.draw do

  resources :questions

  root :to => 'articles#summary'
  
  resources :users
  
  resources :questions

  match 'articles/by_sampletag/:sampletag' => 'articles#by_sampletag'
  match 'articles/by_source/:source' => 'articles#by_source'
  match 'articles/export_by_sampletags' => 'articles#export_by_sampletags'
  match 'articles/summary' => 'articles#summary'
  match 'articles/random' => 'articles#random'
  resources :articles
  
  match 'golds/pick_reasons' => 'golds#pick_reasons'
  match 'golds/edit_reasons' => 'golds#edit_reasons', :via=>:put
  match 'golds/import_reasons' => 'golds#import_reasons'
  match 'golds/export_totals' => 'golds#export_totals'
  resources :golds  
  resources :generic_one_golds, :controller=>"golds", :type=>"GenericOneGold"
  resources :generic_two_golds, :controller=>"golds", :type=>"GenericTwoGold"

  match 'code/by_question/:question_id' => 'code#by_question'
  match 'code/answer' => 'code#answer'
  match 'session/new' => 'session#new'
  match 'session/create' => 'session#create'

  match 'crowd/:action' => 'crowd'

  match 'answers/:action' => 'answers'
  match 'answers/for_article/:id/:question_id' => 'answers#for_article'
  match 'answers/export_totals' => 'articles#answers'

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
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
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
  #       get 'recent', :on => :collection
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
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  #match ':controller(/:action(/:id(.:format)))'
end
